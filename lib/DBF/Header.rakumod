unit class DBF::Header;

use DBF::Field;

#
# ACCESSORS
#

# byte 0 (1 byte)
has $.version is built(False);
# byte 1-3 (3 bytes)
has Date $.last-update is built(False);
# byte 4-7 (32-bit)
has UInt $.records-count is built(False);
# byte 8-9 (16-bit)
has UInt $.header-length is built(False);
# byte 10-11 (16-bit)
has UInt $.record-length is built(False);
# byte 12-13 (2 bytes, fill with 0)
has Buf $.reserved1 is built(False);
# byte 14 (1 byte)
has Bool $.incomplete is built(False);
# byte 15 (1 byte)
has Bool $.encrypted is built(False);
# byte 16-27 (12 bytes)
has Buf $.reserved2 is built(False);
# byte 28 (1 byte)
has Bool $.mdx is built(False);
# byte 29 (1 byte)
has $.lang-id is built(False);
# byte 30-31 (2 bytes, fill with 0)
has Buf $.reserved3 is built(False);

has @.fields is built(False);

multi method read(IO::Handle:D $fh) {
    $!version = $fh.read(1).read-uint8(0);
    my $year = $fh.read(1).read-uint8(0) + 1900;
    my $month = $fh.read(1).read-uint8(0);
    my $day = $fh.read(1).read-uint8(0);
    $!last-update = Date.new: :$year, :$month, :$day;
    $!records-count = $fh.read(4).read-uint32(0, LittleEndian);
    $!header-length = $fh.read(2).read-uint16(0, LittleEndian);
    $!record-length = $fh.read(2).read-uint16(0, LittleEndian);
    $!reserved1 = $fh.read(2);
    $!incomplete = $fh.read(1).read-uint8(0) == 0x01;
    $!encrypted = $fh.read(1).read-uint8(0) == 0x01;
    $!reserved2 = $fh.read(12);
    $!mdx = $fh.read(1).read-uint8(0) == 0x01;
    $!lang-id = $fh.read(1).read-uint8(0);
    $!reserved3 = $fh.read(2);

    loop {
        my $field = DBF::Field.create-field: $fh;
        if $field {
            @!fields.push: $field;
        }
        else {
            last;
        }
    }
}

multi method read(Str:D $path) {
    self.read: $path.IO.open: :r, :bin;
}
