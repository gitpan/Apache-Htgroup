package Apache::Htgroup;

=head1 NAME

Apache::Htgroup - Manage Apache authentication group files

=head1 SYNOPSIS

  use Apache::Htgroup;
  $htgroup = Apache::Htgroup->load($path_to_groupfile);
  &do_something if $htgroup->ismember($user, $group);
  $htgroup->adduser($user, $group);
  $htgroup->deleteuser($user, $group);
  $htgroup->save;

=head1 Important notes about versions 1.x

There has been a change to the API since the 0.9 version. The 0.9
version sucked a lot, and this should be a big improvement in a
lot of ways. Please feel free to contact me and yell at me about
these changes if you like. If there are enough complaints, I'll
try to make it backward compatible. However, given a little work,
I think you'll find the new version superior in every way.

=head1 DESCRIPTION

Manage Apache htgroup files

Please note that this is I<not> a mod_perl module. Please also note
that there is another module that does similar things
(HTTPD::UserManage) and that this is a more simplistic module,
not doing all the things that one does.

Please also note that, in contrast to Version 0.9, changes
to the object are only saved to disk when you call the
C<save> method.

=over 5

=cut

use strict;
use vars qw($VERSION);
$VERSION = ( qw($Revision: 1.14 $) )[1];

=item load

	$htgroup = Apache::Htgroup->load($path_to_groupfile);
     $htgroup = Apache::Htgroup->new();

Returns an Apache::Htgroup object.

Calling C<new()> without an argument creates an empty
htgroup object which you can save to a file once you're
done with it.

=cut

sub new {return load(@_)}

sub load {
	my ($class, $file) = @_;
     my $self = bless {
          groupfile => $file,
          }, $class;
     $self->groups;

	return $self;
}

=item adduser

	$htgroup->adduser( $username, $group );

Adds the specified user to the specified group.

=cut

sub adduser	{
     my $self = shift;
     my ( $user, $group ) = @_;

	return(1) if $self->ismember($user, $group);
     $self->{groups}->{$group}->{$user} = 1;

	return(1);
} 

=item deleteuser

	$htgroup->deleteuser($user, $group);

Removes the specified user from the group.

=cut

sub deleteuser	{
     my $self = shift;
     my ($user, $group) = @_;

     delete $self->{groups}->{$group}->{$user};
	return(1);
}

=item groups

	$groups = $htgroup->groups;

Returns a (reference to a) hash of the groups. The key is the name
of the group. Each value is a hashref, the keys of which are the
group members. I suppose there may be some variety of members
method in the future, if anyone thinks that would be useful.

It is expected that this method will not be called directly, and
it is provided as a convenience only. 

Please see the section below about internals for an example
of the data structure.

=cut

sub groups {
	my $self = shift;

     return $self->{groups} if defined $self->{groups};

     $self->reload;

	return $self->{groups};
}

=item reload

     $self->reload;

If you have not already called save(), you can call reload()
and get back to the state of the object as it was loaded from
the original file.

=cut

sub reload {
     my $self = shift;

     if ($self->{groupfile})   {
	
          open (FILE, $self->{groupfile}) || die (
               "Was unable to open group file $self->{groupfile}: $!" );
	     while (my $line = <FILE>)	{
		     chomp $line;
     
		     my ($group, $members) = split /:\s*/,$line;
     
               foreach my $user ( split /\s+/, $members) {
                    $self->{groups}->{$group}->{$user} = 1;
               }
	     }
          close FILE;

     } else {
          $self->{groups} = {};
     }
}

=item save

	$htgroup->save;
     $htgroup->save($file);

Writes the current contents of the htgroup object back to the
file. If you provide a $file argument, C<save> will attempt to
write to that location.

=cut

sub save {
     my $self = shift;
     my $file = shift || $self->{groupfile};

	open (FILE, ">$file") || 
          die ("Was unable to open $file for writing: $!");

     foreach my $group ( keys %{$self->{groups}} )   {
          my $members = join ' ', keys %{$self->{groups}->{$group}};
		print FILE "$group: $members\n";
	}
	close FILE;

	return(1);
}

=item ismember

	$foo = $htgroup->ismember($user, $group);

Returns true if the username is in the group, false otherwise

=cut

sub ismember	{
     my $self = shift;
	my ($user, $group) = @_;

     return ($self->{groups}->{$group}->{$user}) ?  1 : 0 ;
}

1;

=cut

=head1 Internals

Although this was not the case in earlier versions, the internal
data structure of the object looks something like the following:

 $obj = { groupfile => '/path/to/groupfile',
          groups => { group1 => { 'user1' => 1,
                                  'user2' => 1, 
                                  'user3' => 1
                                },
                      group2 => { 'usera' => 1,
                                  'userb' => 1, 
                                  'userc' => 1
                                },
                    }
        };

Note that this data structure is subject to change in the future,
and is provided mostly so that I can remember what the heck I was
thinking when I next have to look at this code.

=head1 Adding groups

A number of folks have asked for a method to add a new group. This
is unnecessary. To add a new group, just start adding users to 
a new group, and the new group will magically spring into existance.

=head1 ToDo

Need to add a decent test suite, but apart from that, I think that
this is pretty good.

=head1 AUTHOR

Rich Bowen, rbowen@rcbowen.com

=head1 HISTORY

     $Log: Htgroup.pm,v $
     Revision 1.14  2001/02/24 21:27:50  rbowen
     Added space between "group:" and the first user, as per the documentation.

     Revision 1.13  2001/02/23 04:13:12  rbowen
     Apparently Perl 5.005_02 was getting grumpy about my use of $Revision: 1.14 $
     to set the VERSION number. Fixed.

     Revision 1.12  2001/02/23 03:16:58  rbowen
     Fixed bug in reload that was effectively breaking everything else.
     It would let you build files from scratch, but not load existing
     files correctly. Added test suite also, which should help

     Revision 1.11  2001/02/21 03:14:04  rbowen
     Fixed reload to work as advertised. groups now calls reload internally
     the first time you call it.

     Version 0.9 -> 1.10 contains a number of important changes.
     As mentioned above, the API has changed, as well as the internal
     data structure. Please read the documentation very carefully.

=cut
