use Flapp qw/-m -s -w/;

sub{
    shift->recursive_do({
        array_ref => sub{
            my($next, $ref) = @_;
            $next->($_[1] = ref $ref eq 'ARRAY' ? [@$ref] : bless [@$ref], ref $ref);
        },
        hash_ref => sub{
            my($next, $ref) = @_;
            $next->($_[1] = ref $ref eq 'HASH' ? {%$ref} : bless {%$ref}, ref $ref);
        },
        unexpected_ref => sub{
            1;
        },
    }, my $v = shift);
    $v;
};
