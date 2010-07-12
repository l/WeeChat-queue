#
# queue.pl is written
# by "AYANOKOUZI, Ryuunosuke" <i38w7i3@yahoo.co.jp>
# under GNU General Public License v3.
#

use strict;
use warnings;

weechat::register("queue", "AYANOKOUZI, Ryuunosuke", "0.1.0", "GPL3", "command queueing", "", "");
weechat::hook_timer(10 * 1000, 0, 0, "worker", "");

weechat::hook_command(
	"showqueue",
	"show queue",
	"",
	"",
	"",
	"showqueue",
	"",
);

weechat::hook_command(
	"enqueue",
	"push queue",
	"command",
	"command: weechat command",
	"",
	"enqueue",
	"",
);

weechat::hook_command(
	"dequeue",
	"shift queue",
	"",
	"",
	"",
	"dequeue",
	"",
);

my @queue = ();

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
