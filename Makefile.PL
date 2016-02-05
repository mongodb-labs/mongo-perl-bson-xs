use strict;
use warnings;

use lib 'inc';
use BSONConfig;

BSONConfig::check_for_compiler();

use 5.008001;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "XS implementation of MongoDB's BSON serialization",
  "AUTHOR" => "David Golden <david\@mongodb.com>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "BSON-XS",
  "LICENSE" => "apache",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME" => "BSON::XS",
  "OBJECT" => "xs/XS\$(OBJ_EXT) bson/bson-atomic\$(OBJ_EXT) bson/bson-clock\$(OBJ_EXT) bson/bson-context\$(OBJ_EXT) bson/bson-error\$(OBJ_EXT) bson/bson-iso8601\$(OBJ_EXT) bson/bson-iter\$(OBJ_EXT) bson/bson-keys\$(OBJ_EXT) bson/bson-md5\$(OBJ_EXT) bson/bson-memory\$(OBJ_EXT) bson/bson-oid\$(OBJ_EXT) bson/bson-reader\$(OBJ_EXT) bson/bson-string\$(OBJ_EXT) bson/bson-timegm\$(OBJ_EXT) bson/bson-utf8\$(OBJ_EXT) bson/bson-value\$(OBJ_EXT) bson/bson-version\$(OBJ_EXT) bson/bson-writer\$(OBJ_EXT) bson/bson\$(OBJ_EXT)",
  "PREREQ_PM" => {
    "Carp" => 0,
    "DateTime" => 0,
    "Moo" => 0,
    "Types::Standard" => 0,
    "XSLoader" => 0,
    "boolean" => 0,
    "if" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "DateTime::Tiny" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Math::BigInt" => 0,
    "MongoDB" => 0,
    "MongoDB::DBRef" => 0,
    "MongoDB::OID" => 0,
    "Test::Deep" => "0.086",
    "Test::Fatal" => 0,
    "Test::More" => "0.96",
    "Tie::IxHash" => 0,
    "Time::Moment" => 0,
    "constant" => 0,
    "lib" => 0
  },
  "VERSION" => "v0.1.0",
  "XS" => {
    "xs/XS.xs" => "xs/XS.c"
  },
  "clean" => {
    "FILES" => "xs/XS\$(OBJ_EXT) bson/bson-atomic\$(OBJ_EXT) bson/bson-clock\$(OBJ_EXT) bson/bson-context\$(OBJ_EXT) bson/bson-error\$(OBJ_EXT) bson/bson-iso8601\$(OBJ_EXT) bson/bson-iter\$(OBJ_EXT) bson/bson-keys\$(OBJ_EXT) bson/bson-md5\$(OBJ_EXT) bson/bson-memory\$(OBJ_EXT) bson/bson-oid\$(OBJ_EXT) bson/bson-reader\$(OBJ_EXT) bson/bson-string\$(OBJ_EXT) bson/bson-timegm\$(OBJ_EXT) bson/bson-utf8\$(OBJ_EXT) bson/bson-value\$(OBJ_EXT) bson/bson-version\$(OBJ_EXT) bson/bson-writer\$(OBJ_EXT) bson/bson\$(OBJ_EXT)"
  },
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Carp" => 0,
  "DateTime" => 0,
  "DateTime::Tiny" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Math::BigInt" => 0,
  "MongoDB" => 0,
  "MongoDB::DBRef" => 0,
  "MongoDB::OID" => 0,
  "Moo" => 0,
  "Test::Deep" => "0.086",
  "Test::Fatal" => 0,
  "Test::More" => "0.96",
  "Tie::IxHash" => 0,
  "Time::Moment" => 0,
  "Types::Standard" => 0,
  "XSLoader" => 0,
  "boolean" => 0,
  "constant" => 0,
  "if" => 0,
  "lib" => 0,
  "namespace::clean" => 0,
  "strict" => 0,
  "version" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{

    package MY;

    use Config;

    sub constants {
        my $self = shift;

        my $ccflags = $self->{CCFLAGS} || $Config{ccflags};
        $ccflags = "" unless defined $ccflags;

        my $libs = $self->{LIBS};
        $libs = "" unless defined $libs;

        my $ldflags = $self->{LDFLAGS};
        $ldflags = "" unless defined $ldflags;

        $ccflags .= " -Wall -Wextra -Wuninitialized -Wdeclaration-after-statement"
          if BSONConfig::HAS_GCC() && ( $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING} );

        # Perl on older Centos doesn't come with this by default
        $ccflags .= " -D_GNU_SOURCE"
          if BSONConfig::HAS_GCC() && $ccflags !~ /-D_GNU_SOURCE/;

        # openbsd needs threaded perl *or* single-threaded but with libpthread, so
        # we check specifically for that
        if ( $^O eq 'openbsd' ) {
            my $has_libpthread = qx{/usr/bin/ldd $Config{perlpath}} =~ /libpthread/;
            die "OS unsupported: OpenBSD support requires a perl linked with libpthread"
              unless $has_libpthread;
        }

        # check for 64-bit
        if ( $Config{use64bitint} ) {
            $ccflags .= " -DMONGO_USE_64_BIT_INT";
        }

        # check for big-endian
        my $endianess = $Config{byteorder};
        if ( $endianess == 4321 || $endianess == 87654321 ) {
            $ccflags .= " -DMONGO_BIG_ENDIAN=1 ";
            if ( $] lt '5.010' ) {
                die "OS unsupported: Perl 5.10 or greater is required for big-endian platforms";
            }
        }

        # needed to compile bson library
        $ccflags .= " -DBSON_COMPILATION ";

        my $conf = BSONConfig::configure_bson();

        if ( $conf->{BSON_WITH_OID32_PT} || $conf->{BSON_WITH_OID64_PT} ) {
            my $pthread = $^O eq 'solaris' ? " -pthreads " : " -pthread ";
            $ccflags .= $pthread;
            $ldflags .= $pthread;
        }

        if ( $conf->{BSON_HAVE_CLOCK_GETTIME} ) {
            $libs .= " -lrt";
        }

        $self->{INC}     = "-I. -Ibson";
        $self->{CCFLAGS} = $ccflags;
        $self->{LIBS}    = $libs;
        $self->{LDFLAGS} = $ldflags;

        return $self->SUPER::constants(@_);
    }

    sub const_cccmd {
        my $ret = shift->SUPER::const_cccmd(@_);
        return q{} unless $ret;

        if ( $Config{cc} =~ /^cl\b/i ) {
            warn 'you are using MSVC... we may not have gotten some options quite right.';
            $ret .= ' /Fo$@';
        }
        else {
            $ret .= ' -o $@';
        }

        return $ret;
    }

    sub postamble {
        my $txt = <<'EOF';
$(OBJECT) : perl_mongo.h

cover : pure_all
        HARNESS_PERL_SWITCHES=-MDevel::Cover make test

ptest : pure_all
        HARNESS_OPTIONS=j9 make test

EOF
        $txt =~ s/^ +/\t/mg;
        return $txt;
    }

}
