use Flapp qw/-m -s/; #no warnings;

sub{
    my $util = shift;
    my $ref = ref $_[0];
    
    if($ref && $ref ne 'SCALAR'){
        die qq{Invalid ref "$ref"} if !$_[1] && $ref ne 'HASH'; #allow blessed hash if $_[1]
        my $h = shift;
        my @q;
        foreach(sort keys %$h){
            $util->uri_escape(\(my $k = $_));
            !($ref = ref $h->{$_}) ? push(@q, "$k=".$util->uri_escape($h->{$_})) :
            $ref eq 'ARRAY' ? push(@q, map{ "$k=".$util->uri_escape($_) } @{$h->{$_}}) :
            die qq{Invalid ref "$ref" for key "$_"};
        }
        return @q ? join('&', @q) : '';
    }
    
    my $r = $ref ? shift : do{ \(my $s = shift) };
    use bytes;
    $$r =~ s/([\x00-\)+,\/:-?\[-^`\{-\xFF])/$1 eq ' ' ? '+' : '%'.uc(unpack('H*', $1))/eg;
    $$r;
};
