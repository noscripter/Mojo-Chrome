use Mojo::Base -strict;

use Mojo::Chrome;
use Mojo::IOLoop;
use Mojo::JSON;

binmode(STDOUT, ":utf8");
$|++;

my $chrome = Mojo::Chrome->new->catch(sub{ warn $_[1] });

# this is the example from https://medium.com/@lagenar/using-headless-chrome-via-the-websockets-interface-5f498fb67e0f
# archived at https://web.archive.org/web/20171020022803/https://medium.com/@lagenar/using-headless-chrome-via-the-websockets-interface-5f498fb67e0f
# requires a running chome exposing debugging interface on port 9000
# on my mac that is /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --headless --remote-debugging-port=9000

my $get = 'https://news.google.com/news/?ned=us&hl=en';
my $js = <<'JS';
var sel = '[role="heading"][aria-level="2"]';
var headings = document.querySelectorAll(sel);
[].slice.call(headings).map((link)=>{return link.innerText});
JS

Mojo::IOLoop->delay(
  sub { $chrome->load_page({url => $get}, shift->begin) },
  sub {
    my ($delay, $err) = @_;
    die $err if $err;
    $chrome->send_command('Runtime.evaluate', { expression => $js, returnByValue => \1 }, $delay->begin);
  },
  sub {
    my ($delay, $err, $payload) = @_;
    die $err if $err;
    my $result = $payload->{result}{value};
    say for @$result;
  }
)->wait;

