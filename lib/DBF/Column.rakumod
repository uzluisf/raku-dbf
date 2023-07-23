use DBF::ColumnType;

unit class DBF::Column;

subset ColumnName of Str where {
    $_.chars != 0
    || die "column name cannot be an empty string"
};

subset ColumnType of Str where {
    $_ (elem) <C N I F Y D T L M B G +>
    || die "Undefined column type ($_)"
};

subset FieldLength of Int where {
    $_ >= 0
    || die "field length must be 0 or greater"
};

my %TYPECAST-CLASS := Map.new(
  'C', DBF::ColumnType::String,
  'N', DBF::ColumnType::Number,
  'I', DBF::ColumnType::SignedLong,
  'F', DBF::ColumnType::Float,
  'Y', DBF::ColumnType::Currency,
  'D', DBF::ColumnType::Date,
  'T', DBF::ColumnType::DateTime,
  'L', DBF::ColumnType::Boolean,
  'M', DBF::ColumnType::Memo,
  'B', DBF::ColumnType::Double,
  'G', DBF::ColumnType::General,
  '+', DBF::ColumnType::SignedLong2,
);

has ColumnName:D $.name is required;
has ColumnType:D $.type is required;
has FieldLength:D $.length is required;
has UInt:D $.decimal is required;
has $.encoding;
has $.version;

#| Returns C<True> if the column is a memo.
method memo(--> Bool:D) {
    $!type eq 'M';
}

method underscored-name(--> Str:D) {
    $!name
    .subst(/'::'/, '/', :g)
    .subst(/(<[A..Z]>+)(<[A..Z]><[a..z]>)/, { "$0_$1" }, :g)
    .subst(/(<[a..z \d]>)(<[A..Z]>)/, { "$0_$1" }, :g)
    .trans(['-'] => ['_'])
    .lc
}

method clean($value --> Str:D) {
    $value
    .subst(/\x[00]/, '', :g)
    .subst(/<-[ \x[20] .. \x[7E] ]>/, '', :g)
    .trim
}

method typecast-class {
    my $class = $!length == 0
    ?? Nil
    !! %TYPECAST-CLASS{$!type};
    $class.new: :$!decimal, :$!encoding;
}
