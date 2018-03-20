use warnings;
use strict;
use HTML::Strip;
use open ':std', ':encoding(UTF-8)';

sub WordList{
    my $url = $_[0];
    `curl -sA 'Chrome' -L '$url' -o searchfile.html`;

    my $lineDump;
    my %wordHash; #= %{$_[1]};
    my @wordArray;
    my $arrayDump;
    open(FILE,"searchfile.html") or die "Cannot open file \n";

    while(my $readLine = <FILE>){
        $lineDump .= lc $readLine;
    }

    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse($lineDump);
    $hs->eof;
    close FILE;

    #Array is stored Word1\nWord2\nWord3\n...

    open(FILE, "arraymap.txt") or die "Cannot open arraymap file\n";
    while(defined (my $readLine = <FILE>)){
        $arrayDump .= "$readLine";
    }
    close FILE;

    @wordArray = split("\n", $arrayDump);
    %wordHash = map { $_ => 1  } @wordArray;

    my @split = split("\n", $clean_text);

    foreach my $f (@split){
        my @wordSplit = split(/\s+/, $f);
        foreach my $t (@wordSplit){
            if(!($t =~ /\s+/) && !($t =~ /\W+/) && !($t eq "") && !($t =~ /\d+/)){
                if(defined $wordHash{(lc $t)}){
                    #do nothing as word already exists in the map
                }else{
                    #Add both the word to the array and the hash
                    $wordArray[$#wordArray + 1] = lc $t;
                    $wordHash{$t} = 1;
                }
            }
        }
    }

    open(FILE,">" ."arraymap.txt") or die "Cannot open arraymap file\n";
    foreach my $t (@wordArray){
        print FILE "$t\n";
    }
    close FILE;

    print "Complete word dump\n";
}

sub TrainingList{
    my $url = $_[0];
    my $trainingLike = $_[1];
    `curl -sA 'Chrome' -L '$url' -o searchfile.html`;

    my $lineDump;
    my %wordHash; #= %{$_[1]};
    my @wordArray;
    my $arrayDump;
    open(FILE,"searchfile.html") or die "Cannot open file \n";

    while(my $readLine = <FILE>){
        $lineDump .= lc $readLine;
    }

    my $hs = HTML::Strip->new();
    my $clean_text = $hs->parse($lineDump);
    $hs->eof;
    close FILE;

    #Array is stored Word1\nWord2\nWord3\n...
    open(FILE, "arraymap.txt") or die "Cannot open arraymap file\n";
    while(defined (my $readLine = <FILE>)){
        $arrayDump .= "$readLine";
    }
    close FILE;

    @wordArray = split("\n", $arrayDump);
    %wordHash = map { $_ => 1  } @wordArray;

    my @split = split("\n", $clean_text);
    my $count = 0;
    my $trainingLine = $trainingLike;
    my %addedHash;
    my @addedArray;
    foreach my $f (@split){
        my @wordSplit = split(/\s+/, $f);
        foreach my $t (@wordSplit){
            if(defined $wordHash{$t} && !(defined $addedHash{$t})){
                $count = 0;
                my $added = 0;
                while(defined $wordArray[$count] && $added == 0){
                    if($wordArray[$count] eq $t){
                        $count++;
                        $addedHash{$t} = 1;
                        $addedArray[$#addedArray+1] = $count;
                        #$trainingLine .= " $count:1";
                        $added++;
                    }else{
                        $count++;
                    }
                }
            }
        }
    }

    my @sortedArray = sort{$a <=> $b}(@addedArray);

    foreach my $t (@sortedArray){
        $trainingLine .= " $t:1";
    }

    open(FILE,"+>>" ."trainingdata") or die "Cannot open trainingdata file\n";
    print FILE "$trainingLine\n";
    close FILE;

    print "Complete training line\n";
}

open(FILE2, "links") or die "Cannot open arraymap file\n";
    while(my $readLine = <FILE2>){
        my @split = split("\n", $readLine);
        $readLine = $split[0];
        if(!($readLine =~ /#+/)){
            print "$readLine\n";
            WordList($readLine);
        }
    }
close FILE2;


open(FILE2, "links") or die "Cannot open arraymap file\n";
`rm trainingdata`;
my $like;
while(my $readLine = <FILE2>){
    my @split = split("\n", $readLine);
    $readLine = $split[0];
    if(!($readLine =~ /#+/)){
        print "$like:$readLine\n";
        TrainingList($readLine, $like);
    }else{
        if($readLine =~ /#0/){
            $like = 0;
        }else{
            $like = 1;
        }
    }
}
close FILE2;

print(`./libsvm/svm-train trainingdata`);
print "\nTesting Model against training data\n";
print(`./libsvm/svm-predict trainingdata trainingdata.model predict`);
print "\nBegin testing against selection\n";

open(FILE2, "Testlinks") or die "Cannot open arraymap file\n";
`rm trainingdata`;
$like = 0;
while(my $readLine = <FILE2>){
    my @split = split("\n", $readLine);
    $readLine = $split[0];
    if(!($readLine =~ /#+/)){
        print "$like:$readLine\n";
        TrainingList($readLine, $like);
    }else{
        if($readLine =~ /#0/){
            $like = 0;
        }else{
            $like = 1;
        }
    }
}
close FILE2;

print "\nEnd of preparing test data for libsvm\n";

print(`./libsvm/svm-predict trainingdata trainingdata.model predictTest`);

print "\nDone\n";
