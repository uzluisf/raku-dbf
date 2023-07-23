unit module DBF::ColumnType;

role Base {
    has Str $.encoding;
    has UInt $.decimal;

    method typecast($value) { ... }
}

class Boolean does Base {
    method typecast(Blob:D $value --> Bool:D) {
        $value.decode('ascii').match(/:i^<[ty]>$/).so
    }
}

class String does Base {
    method typecast(Blob:D $value --> Str:D) {
        $!encoding
        ?? $value.decode($!encoding).trim
        !! $value.decode('utf8-c8').trim;
    }
}

class Number does Base {
    method typecast($value) {
        my $val = $value.decode('ascii').trim;
        return Nil unless $val;
        $!decimal == 0
        ?? $val.Int
        !! $val.Num
    }
}

class SignedLong does Base {
    method typecast(Blob:D $value) {
        X::NYI.new(feature => "{&?ROUTINE.name} in {::?CLASS.^name}");
    }
}

class SignedLong2 does Base {
    method typecast(Blob:D $value) {
        X::NYI.new(feature => "{&?ROUTINE.name} in {::?CLASS.^name}");
    }
}

class Float does Base {
    method typecast(Blob:D $value --> Num:D) {
        $value.decode('ascii').Num
    }
}

class Double does Base {
    method typecast(Blob:D $value) {
        X::NYI.new(feature => "{&?ROUTINE.name} in {::?CLASS.^name}");
    }
}

class Date does Base {
    method typecast(Blob:D $value --> Date:D) {
        my $date = $value.decode('ascii');
        my ($year, $month, $day) = $date.split('/');
        try CORE::Date.new: :$year, :$month, :$day;
    }
}

class DateTime does Base {
    method typecast(Blob:D $value) {
        X::NYI.new(feature => "{&?ROUTINE.name} in {::?CLASS.^name}");
    }
}

class Currency does Base {
    method typecast(Blob:D $value) {
        X::NYI.new(feature => "{&?ROUTINE.name} in {::?CLASS.^name}");
    }
}

class Memo does Base {
    method typecast(Blob:D $value) {
        X::NYI.new(feature => "{&?ROUTINE.name} in {::?CLASS.^name}");
    }
}

class General does Base {
    method typecast(Blob:D $value) {
        X::NYI.new(feature => "{&?ROUTINE.name} in {::?CLASS.^name}");
    }
}
