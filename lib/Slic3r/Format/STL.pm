package Slic3r::Format::STL;
use Moo;

use File::Basename qw(basename);

sub read_file {
    my $self = shift;
    my ($file) = @_;
    
    my $path = Slic3r::encode_path($file);
    die "Failed to open $file\n" if !-e $path;
    
    my $mesh = Slic3r::TriangleMesh->new;
    $mesh->ReadSTLFile($path);
    $mesh->repair;
    
    die "This STL file couldn't be read because it's empty.\n"
        if $mesh->facets_count == 0;
    
    my $model = Slic3r::Model->new;
    
    my $basename = basename($file);
    my $object = $model->add_object(input_file => $file, name => $basename);

    if ($mesh->extruders_count > 1) {
        foreach my $new_mesh (@{$mesh->split_by_extruder}) {
            $new_mesh->repair;
            my $ext_num = $new_mesh->extruder_num;
            my $volume = $object->add_volume(mesh => $new_mesh, name => $basename);
            $volume->config->set('extruder', $ext_num + 1);
        }

    } else {
        my $volume = $object->add_volume(mesh => $mesh, name => $basename);
    }

    return $model;
}

sub write_file {
    my $self = shift;
    my ($file, $mesh, %params) = @_;
    
    $mesh = $mesh->mesh if $mesh->isa('Slic3r::Model');
    
    my $path = Slic3r::encode_path($file);
    
    $params{binary}
        ? $mesh->write_binary($path)
        : $mesh->write_ascii($path);
}

1;
