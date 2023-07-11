use DBF::Header;

unit class DBF::Table;

has IO::Handle $.data is required;
has $.encoding;
has $.memo;

has DBF::Header $.header is built(False) handles <
    header-length
    record-count
    record-length
    version
>;

multi method new(IO::Path:D :$data, :$encoding, :$memo) {
    callwith data => $data.open(:r, :binary), :$encoding, :$memo;
}

multi method new(Str:D :$data, :$encoding, :$memo) {
    callwith data => $data.IO.open(:r, :binary), :$encoding, :$memo;
}

submethod TWEAK {
    # Header
    my &safe-seek = self.safe-seek;
    
    $!data.seek(0);
    $!header = DBF::Header.new: data => $!data.read(32);
    
    &safe-seek();
}

method safe-seek {
    my $original-pos = $!data.tell;
    sub { $!data.seek($original-pos) }
}

