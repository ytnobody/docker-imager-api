package YTNOBODY::Imager::API;
use strict;
use warnings;
use Plack::Request;
use Furl;
use Imager;
use Carp;

our $UA_STRING = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.116 Safari/537.36';
our $FURL = Furl->new(timeout => 60, agent => $UA_STRING);

sub fetch_image {
    my $url = shift;
    my $res = $FURL->get($url);
    croak 'could not receive content: '. $res->status_line unless $res->is_success;
    if ($res->content_type !~ /image/) {
        carp 'not image response';
        return;
    }
    return ($res->content, $res->content_type);
}

sub apply_actions {
    my ($img_bin, $mime, @actions) = @_;
    my $modified = $img_bin;

    for my $action (@actions) {
        my $func = sprintf 'action_%s', $action->{name};
        next unless __PACKAGE__->can($func);

        my @params = @{$action->{params}};

        my $image = Imager->new;
        $image->read(data => $modified) or croak $image->errstr;

        my $modified_image = __PACKAGE__->$func($image, @params);
        $modified = undef;
        $modified_image->write(data => \$modified, type => mime_to_type($mime));
    }

    $modified;
}

sub action_width {
    my ($class, $image, $width) = @_;
    my $ratio = $width / $image->getwidth;
    my $height = int($image->getheight * $ratio);
    $image->scale(xpixels => $width, ypixels => $height);
}

sub action_crop {
    my ($class, $image, $x, $y, $width, $height) = @_;
    $image->crop(top => $x, left => $y, width => $width, height => $height);
}

sub mime_to_type {
    my $mime = shift;
    return 
        $mime =~ /jpe?g/i ? 'jpeg' :
        $mime =~ /png/i ? 'png' :
        undef
    ;
}

sub path_to_actions {
    my $path = shift;
    return unless $path =~ /\A\/actions\//;
    map {
        my ($action, @params) = split ':', $_;
        {name => $action, params => \@params};
    } grep {$_ && $_ ne 'actions'} split '/', $path;
}

sub res_error {
    my ($code, $message) = @_;
    [$code, ['Content-type' => 'text/html'], [$message]]
}

sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    my @actions = path_to_actions($req->path) or return res_error(404 => 'not found');

    my $img_url = $req->parameters->as_hashref->{img};
    my ($img_bin, $mime) = fetch_image($img_url) or return res_error(500 => 'could not fetch image');

    my $modified = apply_actions($img_bin, $mime, @actions);

    [200, ['Content-type' => $mime], [$modified]];
};


