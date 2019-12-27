#!/usr/bin/perl -n
#!/usr/bin/env perl

# Graciously from: https://www.perlmonks.org/?node_id=1172178

my $usage;
BEGIN {
    $usage = "Usage: $0 linespec file\n"
           . "  linespec example: 2,5,32-42,4\n"
           . "  this extracts lines 2,4,5 and 32 to 42 from file\n";
    $spec=shift;
    die $usage unless $spec;
    @l=split/,/,$spec;
    for(@l){
        ($s,$e)=split/-/;
        $e||=$s;
        $_=[$s,$e];
    }
}
CHECK {
    unless(@ARGV) {
        push @ARGV, <DATA>;
        chomp @ARGV;
    }
    die $usage unless @ARGV;
    $file = $ARGV[0];
}
# === loop ====
for $l(@l){
    print if $.>=$l->[0] and $.<=$l->[1]
}
# === end ===
#
END {
    if ($file) {
        open $fh,'<', $0;
        @lines = <$fh>;
        close $fh;
        open $fh,'>',$0;
        for(@lines){
            print $fh $_;
            last if /^__DATA__$/;
        }
        print $fh $file,"\n";
    }
}
__DATA__
