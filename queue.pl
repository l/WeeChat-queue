#
# queue.pl is written
# by "AYANOKOUZI, Ryuunosuke" <i38w7i3@yahoo.co.jp>
# under GNU General Public License v3.
#

use strict;
use warnings;
use Data::Dumper;

my @queue = ();
my $conf = &configure();
my $script_name = "queue";
weechat::register($script_name, "AYANOKOUZI, Ryuunosuke", "0.1.1", "GPL3", "command queuing", "", "");
weechat::hook_config("plugins.var.perl.$script_name.*", "config_cb", "");
weechat::hook_command(
	$script_name,
	"queue management for any weechat command, message to some buffer, erc...",
	"[|[list|del]|[add command]]",
	"
   list: show queue subcommand
    del: shift queue subcommand
    add: push queue subcommand
command: any weechat command

Examples:
/queue
        Synonymous with `/queue list'
/queue list
        Display a list of commands on queue.
/queue del
        Delete 1st command from queue.
/queue add /msg #weechat Hi, there!
        Add command `/msg #weechat Hi, there!' to queue.
/queue add hello weechat!
        Add command `hello weechat!' to queue.
        Messsage `hello weechat!' will send from the buffer.

Vars:
/set plugins.var.perl.$script_name.interval 100000
        set interval between two calls by millisecond units.
/set plugins.var.perl.$script_name.align_second 0
        set alignment on a second. 
/set plugins.var.perl.$script_name.max_calls 10
        set number of calls to timer (if 0, then timer has no end)
",
	"list||del||add",
	"queue",
	"",
);

sub config_cb
{
	my $data = shift;
	my $option = shift;
	my $value = shift;
#	weechat::print('', Dumper $data);
#	weechat::print('', Dumper $option);
#	weechat::print('', Dumper $value);
#	weechat::print('', Dumper $conf);
	if ($conf->{hook}) {
		weechat::unhook($conf->{hook});
	}
	$conf = &configure();
#	weechat::print('', Dumper $conf);
	return weechat::WEECHAT_RC_OK;
}

sub configure
{
	my $conf = {
		interval => 100*1000,
		align_second => 0,
		max_calls => 10,
	};
	while (my ($key, $val) = each %{$conf}) {
		if (!weechat::config_is_set_plugin($key)) {
			weechat::config_set_plugin($key, $val);
		}
		$conf->{$key} = weechat::config_get_plugin($key);
	}
	$conf->{hook} = weechat::hook_timer($conf->{interval}, $conf->{align_second}, $conf->{max_calls}, "worker", "");
	return $conf;
}

sub queue
{
	my $data = shift;
	my $buffer = shift;
	my ($subcommand, $args) = split / /, shift, 2;
	if (! $subcommand) {
		$subcommand = 'list';
	}
	if ($subcommand eq 'list') {
		&showqueue($data, $buffer, $args);
	} elsif ($subcommand eq 'add') {
		&enqueue($data, $buffer, $args);
	} elsif ($subcommand eq 'del') {
		&dequeue($data, $buffer, $args);
	} else {
		weechat::print("", "ERROR: unregistered subcommand '$subcommand`");
	}
	return weechat::WEECHAT_RC_OK;
}

sub dequeue
{
	if (! @queue) {
		return weechat::WEECHAT_RC_OK;
	}
	return shift @queue;
}

sub enqueue
{
	my $data = shift;
	my $buffer = shift;
	my $args = shift;
	foreach my $queue (reverse @queue) {
		if ($queue->{data} eq $data
				&& $queue->{buffer} eq $buffer
				&& $queue->{args} eq $args
		   ) {
			return weechat::WEECHAT_RC_OK;
		}
	}
	push @queue, {
		data => $data,
		buffer => $buffer,
		args => $args,
	};
	return weechat::WEECHAT_RC_OK;
}

sub showqueue
{
	if (! @queue) {
		weechat::print("", "Empty queue.");
		return weechat::WEECHAT_RC_OK;
	}
	my $i = 0;
	my $format = "% 3d % 6s %10s %s";
	weechat::print("", "NO.   DATA     BUFFER ARGS");
	foreach my $queue (@queue) {
		weechat::print("", sprintf($format,
					$i,
					$queue->{data},
					$queue->{buffer},
					$queue->{args},
					)
			      );
		$i++;
	}
	return weechat::WEECHAT_RC_OK;
}

sub worker
{
	if (! @queue) {
		return weechat::WEECHAT_RC_OK;
	}
	my $queue = &dequeue();
	weechat::command($queue->{buffer}, $queue->{args});
	return weechat::WEECHAT_RC_OK;
}
