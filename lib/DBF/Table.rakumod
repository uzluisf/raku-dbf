use DBF::Header;
use DBF::Column;
use DBF::Record;
use DBF::Bufio;

unit class DBF::Table;

constant $DELETION-FLAG = 0x2A;
constant $FIELDS-TERMINATOR-FLAG = 0x0D;
constant $DBASE2-HEADER-SIZE = 8;
constant $DBASE3-HEADER-SIZE = 32;
constant $DBASE7-HEADER-SIZE = 68;

constant %VERSIONS := Map.new:
    '02', 'FoxBase',
    '03', 'dBase III without memo file',
    '04', 'dBase IV without memo file',
    '05', 'dBase V without memo file',
    '07', 'Visual Objects 1.x',
    '30', 'Visual FoxPro',
    '32', 'Visual FoxPro with field type Varchar or Varbinary',
    '31', 'Visual FoxPro with AutoIncrement field',
    '43', 'dBASE IV SQL table files, no memo',
    '63', 'dBASE IV SQL system files, no memo',
    '7b', 'dBase IV with memo file',
    '83', 'dBase III with memo file',
    '87', 'Visual Objects 1.x with memo file',
    '8b', 'dBase IV with memo file',
    '8c', 'dBase 7',
    '8e', 'dBase IV with SQL table',
    'cb', 'dBASE IV SQL table files, with memo',
    'f5', 'FoxPro with memo file',
    'fb', 'FoxPro without memo file'
;

has IO::Handle $.data is required;
has Str $.encoding;
has $.memo;

has DBF::Header $.header handles <
    header-length
    record-count
    record-length
    version
> is built(False);

has DBF::Column @.columns is built(False); 

submethod TWEAK {
    # Header
    my &rewind-pointer = self!safe-seek;
    $!data.seek(0);
    $!header = DBF::Header.new: data => $!data.read(32);
    &rewind-pointer();

    # Columns/Fields
    self!build-columns;
}

multi method new(IO::Path:D :$data!, Str :$encoding, :$memo) {
    callwith data => $data.open(:r, :binary), :$encoding, :$memo;
}

method header-size(::?CLASS:D: --> UInt:D) {
    do given $!header.version {
        when 0x02             { $DBASE2-HEADER-SIZE }
        when (0x04, 0x8C).any { $DBASE7-HEADER-SIZE }
        when 0x3              { $DBASE3-HEADER-SIZE }
        default               { die 'version not supported' }
    }
}

method record(::?CLASS:D: UInt:D $pos --> DBF::Record:D) {
    fail 'DBF file has no defined columns' unless @!columns.elems;
 
    fail X::OutOfRange.new(
        :what('Index out of range'),
        :got($pos),
        :range("0..{self.record-count - 1}"),
    ) unless 0 ≤ $pos < self.record-count;

    my &rewind-pointer = self!safe-seek;
    self!seek-to-record($pos);

    if self!record-deleted {
        &rewind-pointer();
        return Nil;
    }

    my $data = $!data.read($!header.record-length);
    &rewind-pointer();

    DBF::Record.new:
        :data(DBF::Bufio.new($data)),
        :@!columns,
        :version(self.version),
    ;
}

method AT-POS(::?CLASS:D: UInt:D $pos --> DBF::Record:D) {
    self.record: $pos;
}

method column-names(::?CLASS:D: --> Array:D) {
    @!columns>>.name;
}

method close(::?CLASS:D:) {
    $!data.close;
}

method version-description(::?CLASS:D: --> Str:D) {
    %VERSIONS{self.version};
}

#
# PRIVATE METHODS
#

# Read field descriptor array data and create DBF::Column object from each
# field descriptor.
method !build-columns(--> Nil) {
    my &rewind-pointer = self!safe-seek;
    $!data.seek(self.header-size);

    until self!end-of-fields {
        my $field = $!data.read(self.header-size);
        given $!header.version {
            when 0x02 {
                X::NYI.new(feature => "version {$!header.version}").throw;
            }
            when (0x04, 0x8C).any {
                X::NYI.new(feature => "version {$!header.version}").throw;
            }
            when 0x3 {
	            my $name = $field.subbuf(0, 10).decode('ascii').subst(/\x[00]+/, '');
	            my $type = $field.subbuf(11, 1).decode('ascii');
	            my $length = $field[16];
	            my $decimal = $field[17];

                @!columns.push(
                    DBF::Column.new:
                        :$name, :$type, :$length, :$decimal,
                        :encoding(self.encoding), :version(self.version),
                );
            }
        }
    }

    my $fields-terminator = $!data.read(1)[0];
    unless $fields-terminator == $FIELDS-TERMINATOR-FLAG {
        warn "didn't find field terminator flag, data might be off";
    }

    &rewind-pointer();
}

# Returns C<True> if all field descriptors have been read. Otherwise, C<False>.
method !end-of-fields(--> Bool:D) {
    my &rewind-pointer = self!safe-seek;
    my $flag = $!data.read(1);
    &rewind-pointer();
    return $flag[0] == $FIELDS-TERMINATOR-FLAG;
}

# Returns C<True> if record is marked as deleted. Otherwise, C<False>.
method !record-deleted(--> Bool:D) {
    $!data.read(1) == $DELETION-FLAG;
}

# Returns a closure around file pointer's current position. This allows
# to rewind the file pointer's position after a read operation.
# TODO: Can it be done more idiomatically in Raku?
method !safe-seek {
    my $original-pos = $!data.tell;
    sub { $!data.seek($original-pos) }
}

# Seeks an offset off the header's length from the file pointer's current position.
method !seek($offset) {
    $!data.seek($!header.header-length + $offset, SeekFromCurrent);
}

# Seeks a record's worth.
method !seek-to-record(UInt $index) {
    self!seek($index * $!header.record-length);
}

