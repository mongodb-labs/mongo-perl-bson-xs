#
#  Copyright 2016 MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use 5.010001;
use strict;
use warnings;

package BSON::XS;
# ABSTRACT: XS implementation of MongoDB's BSON serialization

use version;
our $VERSION = 'v0.8.3';

# cached for efficiency during decoding
# XXX eventually move this into XS
use boolean;
our $_boolean_true  = true;
our $_boolean_false = false;

use XSLoader;
XSLoader::load( "BSON::XS", $VERSION );

# For errors
sub _printable {
    my $value = shift;
    $value =~ s/([^[:print:]])/sprintf("\\x%02x",ord($1))/ge;
    return $value;
}

1;

__END__

=begin :prelude

=head1 END OF LIFE NOTICE

Version v0.8.0 is the final feature release of the MongoDB BSON::XS
library.  The library is now in a 12-month "sunset" period and will
receive security patches and critical bug fixes only.  The BSON::XS
library will be end-of-life and unsupported on August 13, 2020.

=end :prelude

=head1 DESCRIPTION

This module contains an XS implementation for BSON encoding and
decoding.  There is no public API.  Use the L<BSON> module and it will
choose the best implementation for you.

=cut

# vim: ts=4 sts=4 sw=4 et tw=75:
