package Apache::Htgroup;
use strict;
use vars qw($VERSION);
$VERSION = '0.9';

sub new	{
	my ($class, $groupFile) = @_;
	my ($self) = {};
	bless ($self, $class);

	$self->{'groupfile'} = $groupFile;
	return $self;
} # End sub new

sub addUser	{
	my ($self, $username, $groupname) = @_;
	return(1) if $self->isMember($username, $groupname);
	my ($line, $group, $groups);
	
	$groups = $self->groups;
	$groups->{$groupname} .= " $username";
	$self->writeFile($groups) || return(0);
	return(1);
} # End sub addUser

sub deleteUser	{
	my ($self, $username, $groupname) = @_;
	return(0) unless $self->isMember($username, $groupname);
	my ($groups);

	$groups = $self->groups;
	$groups->{$groupname} =~ s/ $username\b//;
	$self->writeFile($groups) || return(0);
	return(1);
} # End sub deletUser

sub groups {
	my ($self) = @_;
	my (%groups, $group, $members, $line);

	open (FILE, $self->{'groupfile'}) || return(0);
	while ($line = <FILE>)	{
		chomp $line;
		($group, $members) = split /:/,$line;
		$groups{$group} = $members;
	}
	close FILE;
	return (\%groups);
} # End sub groups

sub writeFile	{
	my ($self, $groups) = @_;
	my ($group);
	open (FILE, ">$self->{'groupfile'}") || return(0);
	for $group (keys %$groups)	{
		print FILE "$group:$groups->{$group}\n";
	}
	close FILE;
	return(1);
} # End sub writeFile

sub isMember	{
	my ($self, $username, $groupname) = @_;
	my ($groups);

	$groups = $self->groups;
	if ($groups->{$groupname} =~ / $username\b/)	{
		return(1);
	} else {
		return(0);
	}
} # End sub isMember

1;
__END__

=head1 NAME

Apache::Htgroup - Manage Apache authentication group files

=head1 SYNOPSIS

  use Apache::Htgroup;
  $group = new Apache::Htgroup ($path_to_groupfile);
  $foo = $group->isMember($username);
  $group->addUser($username);
  $group->deleteUser($username);

=head1 DESCRIPTION

Manage Apache htgroup files

=over 5

=item new

	$group = new Apache::Htgroup ($path_to_groupfile);

Creates a new object of the Apache::Htgroup class

=item isMember

	$foo = $group->isMember($username);

Returns true if the username is in the group, false otherwise

=item addUser

	$group->addUser($username);

Adds the user to the group.

=item deleteUser

	$group->deleteUser($username);

Removes the specified user from the group.

=item groups

	$groups = $group->groups;

Returns a reference to a hash of the groups. The key is the name of the group,
and the value is a string containing all the users separated by 
spaces - exactly as it appears in the group file.

=item writeFile

	$group->writeFile($groups);

Writes out the group file. $groups is a hashref that looks like the
hash returned by the C<groups> method.

=back

=head1 Bugs/To do/Disclaimer

I wrote this in a real hurry. I knew that it would save time in the
long run if I wrote this as a module, but I did not have the time to 
put in all the doodads that really belong in here.

I really need to have some file locking here, but this is a rush job. I'll
add this some time soon.

Need to have reasonable return values on failure. I'll add this when
I'm in less of a hurry.

Need to add some reasonable tests in test.pl.  Same excuse.

Patches and suggestions welcome.

=head1 AUTHOR

Rich Bowen, rbowen@rcbowen.com

=cut
