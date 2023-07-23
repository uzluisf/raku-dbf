unit class DBF::Bufio;

has Blob:D $!data is required; 
has UInt:D $!length = $!data.elems;
has UInt:D $!pos = 0;

submethod BUILD(:$!data) {}

#| Returns a new C<DBF::Bufio> object.
method new(Blob:D $data) {
    self.bless: :$data;
}

#| Read C<$bytes> from file handle.
method read(::?CLASS:D: UInt(Cool:D) $bytes --> Buf:D) {
   return Nil if self.eof;
   my $len = min $bytes, $!length - $!pos;
   my $buf = Buf.new($!data.subbuf: $!pos, $len);
   $!pos += $len;
   return $buf;
}

#| Move the file pointer to the byte position specified by C<$offset>
#| relative to the location specified by C<$whence>.
method seek(::?CLASS:D: Int:D $offset, SeekType:D $whence --> True) {
    given $whence {
        when SeekFromCurrent {
            die 'cannot seek before position 0' if $!pos + $offset < 0;
            $!pos += $offset;
        }
        when SeekFromEnd {
            die 'offset must be negative when seeking from end of buffer' if $offset >= 0;
            die 'cannot seek before position 0' if $!length + $offset < 0;
            $!pos = $!length + $offset;
        }
        when SeekFromBeginning {
            $!pos = max 0, $offset;
        } 
    }
}

#| Returns buffer's current position.
method tell(::?CLASS:D: --> UInt:D) {
    $!pos;
}

#| Returns C<True> if the end of buffer was reached.
method eof(::?CLASS:D: --> Bool:D) {
    $!pos >= $!length;
}
