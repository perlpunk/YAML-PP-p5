use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
my $xsaccessor = eval "use Class::XSAccessor; 1";
unless ($xsaccessor) {
    diag "\n----------------";
    diag "Class::XSAccessor is not installed. Class attributes might not be checked";
    diag "----------------";
}
all_pod_coverage_ok();
