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

sub imager {
    my $img_bin = shift;
    my $image = Imager->new;
    $image->read(data => $img_bin) or croak $image->errstr;
    $image;
}

sub apply_actions {
    my ($img_bin, $mime, @actions) = @_;
    my $modified = $img_bin;

    for my $action (@actions) {
        my $func = sprintf 'action_%s', $action->{name};
        next unless __PACKAGE__->can($func);

        my @params = @{$action->{params}};

        my $image = imager($modified);

        my $modified_image = __PACKAGE__->$func($image, @params);
        $modified = undef;
        $modified_image->write(data => \$modified, type => mime_to_type($mime));
    }

    $modified;
}

sub mime_to_type {
    my $mime = shift;
    return 
        $mime =~ /jpe?g/i ? 'jpeg' :
        $mime =~ /png/i ? 'png' :
        undef
    ;
}

sub parse_actions {
    my $req = shift;
    my @actions = ($req->parameters->get_all('action'));
    map {
        my ($action, @params) = split ',', $_;
        {name => $action, params => \@params};
    } @actions;
}

sub res_error {
    my ($code, $message) = @_;
    [$code, ['Content-type' => 'text/html'], [$message]]
}

sub action_resize {
    my ($class, $image, $width) = @_;
    my $ratio = $width / $image->getwidth;
    my $height = int($image->getheight * $ratio);
    $image->scale(xpixels => $width, ypixels => $height);
}

sub action_crop {
    my ($class, $image, $x, $y, $width, $height) = @_;
    $image->crop(left => $x, top => $y, width => $width, height => $height);
}

sub action_compose {
    my ($class, $image, $url, $x, $y, $width) = @_;
    my ($overlay_bin, $mime) = fetch_image($url) or return $image;
    my $overlay = imager($overlay_bin);
    if ($width) {
        my $ratio = $width / $overlay->getwidth;
        my $height = int($overlay->getheight * $ratio);
        $overlay = $overlay->scale(xpixels => $width, ypixels => $height);
    }
    $image->compose(src => $overlay, tx => $x, ty => $y);
}

sub action_gray {
    my ($class, $image) = @_;
    $image->convert(preset => 'gray');
}

sub action_mosaic {
    my ($class, $image, $x, $y, $width, $height, $size) = @_;
    $size ||= 10;
    my $cropped = $image->crop(left => $x, top => $y, width => $width, height => $height);
    $cropped->filter(type => 'mosaic', size => $size);
    $image->compose(src => $cropped, tx => $x, ty => $y);
}

sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    return res_error(404 => 'not found') if $req->path ne '/';
    my @actions = parse_actions($req);

    my $img_url = $req->parameters->get('img');

    my ($img_bin, $mime, $modified);
    eval {
        ($img_bin, $mime) = fetch_image($img_url);
        $modified = apply_actions($img_bin, $mime, @actions);
    };
    return res_error(500 => 'error: '.$@. ' Check your request parameters.') if $@;

    [200, ['Content-type' => $mime], [$modified]];
};


