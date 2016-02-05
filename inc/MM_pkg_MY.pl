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

