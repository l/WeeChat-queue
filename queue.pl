#
# queue.pl is written
# by "AYANOKOUZI, Ryuunosuke" <i38w7i3@yahoo.co.jp>
# under GNU General Public License v3.
#

use strict;
use warnings;

weechat::register("queue", "AYANOKOUZI, Ryuunosuke", "0.1.0", "GPL3", "command queuing", "", "");
weechat::hook_timer(100 * 1000, 0, 0, "worker", "");

weechat::hook_command(
	"queue",
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
",
	"list||del||add",
	"queue",
	"",
);

my @queue = ();

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
