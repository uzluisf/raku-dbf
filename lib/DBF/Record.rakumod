use DBF::Column;
use DBF::Bufio;

unit class DBF::Record;

has DBF::Bufio:D $.data is required;
has DBF::Column:D @.columns is required;
has $.version;

has @.keys is built(False);
has @.values is built(False);
has %.attributes is built(False);

submethod TWEAK {
    @!keys = @!columns».name;
    @!values = @!columns.map({ self!init-attribute($^column) });
    %!attributes = %(@!keys Z=> @!values);
}

method AT-KEY(::?CLASS:D: Str:D $key --> Str:D) {
    %!attributes{$key}:exists
    ?? %!attributes{$key} 
    !! do {
        my Int $index = @!columns».underscored-name.first($key, :k);
        $index ?? %!attributes{@!columns[$index].name} !! Nil;
    };
}

#
# PRIVATE METHODS
#

method !get-data(DBF::Column:D $column --> Buf:D) {
    $!data.read($column.length);
}

method !get-memo($column) {
    X::NYI.new(feature => "{&?ROUTINE.name} in {::?CLASS.^name}").throw;
}

method !init-attribute(DBF::Column:D $column) {
    my $value = $column.memo ?? self!get-memo($column) !! self!get-data($column);
    my $class = $column.typecast-class;
    $class.typecast($value);
}
