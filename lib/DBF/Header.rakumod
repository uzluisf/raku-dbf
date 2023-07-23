unit class DBF::Header;

has Buf:D $.data is required;

has UInt $.header-length is built(False);
has UInt $.record-length is built(False);
has UInt $.record-count is built(False);
has $.encoding-key is built(False);
has $.encoding is built(False);
has $.version is built(False);

submethod TWEAK {
    self!read-data;
}

method !read-data(--> Nil) {
    $!version = $!data.subbuf(0, 1)[0].base(16).fmt("%02s");

    given $!version {
        when 0x02 {
            $!record-count = 0;
            $!record-length = 0;
            $!header-length = 521;
        }
        default {
            # TODO: Read remaining info from header
            $!record-count = $!data.read-uint32(4, LittleEndian);
            $!header-length = $!data.read-uint16(8, LittleEndian);
            $!record-length = $!data.read-uint16(10, LittleEndian);
            $!encoding-key = 0;
            $!encoding = 'enc';
        }
    }
}
