package Mojolicious::Plugin::Slackbot::chatbot;
use Mojo::Base 'Mojolicious::Plugin::Slackbot::Base';

sub render {
  my $self = shift;
  return unless my $q = $self->text;
  $q =~ s/\W*evi\W*//g;
  $q =~ s/\s+/_/g;
  my $tx = $self->c->ua->get("https://evi.com/q/$q");
  my $answer;
  if ( $answer = $tx->res->dom->at('div.single_answer div.tk_object h3.tk_text') ) {
    $answer = $answer->text;
  } elsif ( $answer = $tx->res->dom->at('div.tk_common a') ) {
    $answer = $answer->text;
  } else {
    if ( 1 ) {
      return;
    } else {
      $answer = 'Unknown';
    }
  }
  $self->respond(sprintf '%s @%s', $answer, $self->user_name);
}

1;

__END__
$ curl 'http://www.personalityforge.com/api/chat/?apiKey=B9ydtN1bVSbvxALI&hash='$(perl -MMojo::JSON=j -MDigest::SHA=hmac_sha256_hex -E 'print hmac_sha256_hex(q({"message":{"message":"How are you doing today?","chatBotID":6,"timestamp":1416986087},"user":{"firstName":"Tugger","lastName":"Sufani","gender":"m","externalID":"abc-63918457"}}), "EIqpM87m3uote9iQaEsKXrb6eMzORMHG")')'&message='$(perl -MURI::Encode=uri_encode -E 'print uri_encode(q({"message":{"message":"How are you doing today?","chatBotID":6,"timestamp":1416986087},"user":{"firstName":"Tugger","lastName":"Sufani","gender":"m","externalID":"abc-63918457"}}))')
<br><br>Correct parameters and objects received<br>raw message: {"message":{"message":"How are you doing today?","chatBotID":6,"timestamp":1416986087},"user":{"firstName":"Tugger","lastName":"Sufani","gender":"m","externalID":"abc-63918457"}}<br>apiSecret: EIqpM87m3uote9iQaEsKXrb6eMzORMHG<br>Do the following two match?<br>e3bf033dc05d2d59200fec64ee581390d33017b1469583a27b59cb7c78e81f6f<br>e3bf033dc05d2d59200fec64ee581390d33017b1469583a27b59cb7c78e81f6f<br>CORRECT MATCH!<pre>Array
(
    [message] => Array
        (
            [message] => How are you doing today?
            [chatBotID] => 6
            [timestamp] => 1416986087
        )

    [user] => Array
        (
            [firstName] => Tugger
            [lastName] => Sufani
            [gender] => m
            [externalID] => abc-63918457
        )

)
</pre>sent on Wed, 26 Nov 2014 2:14:47 am<br>26 seconds ago. (limit is 300)<br>{"success":1,"errorMessage":"","message":{"chatBotName":"Desti","chatBotID":"6","message":"It's been a tough day but I'm feeling better.","emotion":"normal"}}
