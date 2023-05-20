unit class DBF::Field;

# byte 0-10 (11 bytes)
has Str $.name;
# byte 11 (1 byte)
has $.type;
# byte 12-15 (4 bytes)
has $.reserved1;
# byte 16 (1 byte)
has UInt $.length;
# byte 17 (1 byte)
has UInt $.dec-count;
# byte 18-19 (16-bit) 
has $.reserved2;
# byte 20
has UInt $.work-area-id;
# byte 21-22
has $.reserved3;
# byte 23 (1 byte)
has $.set-fields-flag;
# byte 24-30 (7 bytes)
has $.reserved4;
# byte 31 (1 byte)
has $.index-field-flag;

method create-field(::?CLASS:U: $fh) {
    constant $FIELD-TERMINATOR = 0x0D;
    
    my $name = $fh.read(11);
    
    # we reached the field descriptor terminator. Since we read 10 bytes
    # beyond the field descriptor, we're moving the file pointer back that
    # many bytes.
    if $name[0] == $FIELD-TERMINATOR {
        $fh.seek(-10, SeekFromCurrent);
        return Nil;
    }
    
    $name = $name.decode('ascii').subst(/\x[00]+/, '');
    my $type = $fh.read(1).decode('ascii');
    my $reserved1 = $fh.read(4).read-uint32(0, LittleEndian);
    my $length = $fh.read(1).read-uint8(0);
    my $dec-count = $fh.read(1).read-uint8(0);
    my $reserved2 = $fh.read(2).read-uint16(0, LittleEndian);
    my $work-area-id = $fh.read(1).read-uint8(0);
    my $reserved3 = $fh.read(2).read-uint16(0, LittleEndian);
    my $set-fields-flag = $fh.read(1).read-uint8(0);
    my $reserved4 = $fh.read(7);
    my $index-field-flag = $fh.read(1).read-uint8(0);

    self.new:
        :$name,
        :$type,
        :$reserved1,
        :$length,
        :$dec-count,
        :$reserved2,
        :$work-area-id,
        :$reserved3,
        :$set-fields-flag,
        :$reserved4,
        :$index-field-flag,
    ;
}
