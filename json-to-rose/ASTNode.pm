# See the dyninst/COPYRIGHT file for copyright information.
# 
# We provide the Paradyn Tools (below described as "Paradyn")
# on an AS IS basis, and do not warrant its validity or performance.
# We reserve the right to update, modify, or discontinue this
# software at any time.  We shall have no obligation to supply such
# updates or modifications or any other form of support to you.
# 
# By your use of Paradyn, you understand and agree that we (or any
# other person or entity with proprietary rights in Paradyn) are
# under no obligation to provide either maintenance services,
# update services, notices of latent defects, or correction of
# defects for Paradyn.
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

package ASTNode;

use strict;
use warnings;

use Exporter 'import';
use FindBin;
use lib "$FindBin::Bin";

our @EXPORT_OK = qw(new);

sub new {
    my ( $class, %args ) = @_;
    my $self = {
        type       => $args{type}       // ASTType::LIT_NULL,
        value      => $args{value}      // undef,
        attributes => $args{attributes} // {},
        children   => $args{children}   // [],
        siblings   => $args{siblings}   // [],
    };
    return bless $self, $class;
}

sub new_null_node {
    my ($class) = @_;
    return $class->new( type => ASTType::LIT_NULL );
}

sub new_num_node {
    my ( $class, $value ) = @_;
    return $class->new( type => ASTType::LIT_NUM, value => $value );
}

sub new_var_node {
    my ( $class, $id ) = @_;
    return $class->new( type => ASTType::LIT_VAR, value => $id );
}

sub new_id_node {
    my ( $class, $id ) = @_;
    return $class->new( type => ASTType::LIT_ID, value => $id );
}

sub new_hex_node {
    my ( $class, $hex ) = @_;
    return $class->new( type => ASTType::LIT_HEX, value => $hex );
}

sub new_bin_node {
    my ( $class, $bin ) = @_;
    return $class->new( type => ASTType::LIT_BIN, value => $bin );
}

sub new_str_node {
    my ( $class, $value ) = @_;
    return $class->new( type => ASTType::LIT_STR, value => $value );
}

sub new_bool_node {
    my ( $class, $bool ) = @_;
    return $class->new( type => ASTType::LIT_BOOL, value => $bool );
}

sub new_unit_node {
    my ($class) = @_;
    return $class->new( type => ASTType::LIT_UNIT );
}

sub new_vec_node {
    my ( $class, $value ) = @_;
    return $class->new( type => ASTType::LIT_VEC, value => $value );
}

sub new_list_node {
    my ( $class, $value ) = @_;
    return $class->new( type => ASTType::LIT_LIST, value => $value );
}

sub new_lit_node {
    my ( $class, $value ) = @_;
    return $class->new( type => ASTType::EXP_LIT, value => $value );
}

sub new_func_node {
    my ( $class, $id, $args ) = @_;
    return $class->new(
        type     => ASTType::EXP_FUNC,
        value    => $id,
        children => $args
    );
}

sub new_tuple_node {
    my ( $class, $tuple_elem ) = @_;
    return ASTNode->new( type => ASTType::EXP_TUPLE, children => $tuple_elem );
}

sub new_wild_node {
    return ASTNode->new( type => ASTType::EXP_WILD );
}

sub new_block_node {
    my ( $class, $asts ) = @_;
    return $class->new( type => ASTType::EXP_BLOCK, children => $asts );
}

sub new_for_node {
    my ( $class, $i, $init, $fini, $step, $ord, $block ) = @_;
    return $class->new(
        type       => ASTType::EXP_FOR,
        value      => $i,
        children   => [ $init, $fini, $step, $block ],
        attributes => { ord => $ord }
    );
}

sub new_while_node {
    my ( $class, $cond, $block ) = @_;
    return $class->new(
        type     => ASTType::EXP_WHILE,
        children => [ $cond, $block ]
    );
}

sub new_assign_node {
    my ( $class, $id, $exp ) = @_;
    return $class->new(
        type     => ASTType::EXP_ASSIGN,
        value    => $id,
        children => [$exp]
    );
}

sub new_match_node {
    my ( $class, $id, $match_list_node ) = @_;
    return ASTNode->new(
        type     => ASTType::EXP_MATCH,
        value    => $id,
        children => $match_list_node
    );
}

sub new_match_op_node {
    my ( $class, $key, $value ) = @_;
    return ASTNode->new(
        type     => ASTType::EXP_MATCH_OP,
        value    => $key,
        children => [$value]
    );
}

sub new_app_node {
    my ( $class, $id, $args ) = @_;
    return ASTNode->new(
        type     => ASTType::EXP_APP,
        value    => $id,
        children => $args
    );
}

sub new_return_node {
    my ($class) = @_;
    return $class->new( type => ASTType::EXP_RETURN );
}

sub new_field_node {
    my ( $class, $var, $field ) = @_;
    return $class->new(
        type  => ASTType::EXP_FIELD,
        value => { var => $var, field => $field }
    );
}

sub new_convert_node {
    my ( $class, $conv_insn, $conv_type ) = @_;
    return $class->new(
        type  => ASTType::EXP_CONVERT,
        value => { insn => $conv_insn, type => $conv_type }
    );
}

sub new_exception_node {
    my ($class) = @_;
    return $class->new( type => ASTType::EXP_EXCEPTION );
}

sub new_ite_node {
    my ( $class, $cond, $if, $else ) = @_;
    return $class->new(
        type     => ASTType::EXP_FUNC,
        value    => ASTType::ROSE_OP_ITE,
        children => [ $cond, $if, $else ]
    );
}

sub new_vec_index_node {
    my ( $class, $vector, $index ) = @_;
    return $class->new(
        type     => ASTType::LIT_VEC_INDEX,
        value    => $vector,
        children => [$index]
    );
}

sub new_vec_range_node {
    my ( $class, $vector, $start, $end ) = @_;
    return $class->new(
        type     => ASTType::LIT_VEC_RANGE,
        value    => $vector,
        children => [ $start, $end ]
    );
}

sub new_vec_concat_node {
    my ( $class, $vector, $concat ) = @_;
    return $class->new(
        type     => ASTType::LIT_VEC_CONCAT,
        value    => $vector,
        children => [$concat]
    );
}

sub is_null_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_NULL;
}

sub is_id_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_ID;
}

sub is_var_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_VAR;
}

sub is_num_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_NUM;
}

sub is_bin_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_BIN;
}

sub is_str_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_STR;
}

sub is_hex_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_HEX;
}

sub is_bool_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_BOOL;
}

sub is_unit_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_UNIT;
}

sub is_vec_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_VEC;
}

sub is_list_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_LIST;
}

sub is_func_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_FUNC;
}

sub is_tuple_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_TUPLE;
}

sub is_wild_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_WILD;
}

sub is_block_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_BLOCK;
}

sub is_for_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_FOR;
}

sub is_while_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_WHILE;
}

sub is_assign_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_ASSIGN;
}

sub is_match_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_MATCH;
}

sub is_match_op_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_MATCH_OP;
}

sub is_app_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_APP;
}

sub is_return_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_RETURN;
}

sub is_field_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_FIELD;
}

sub is_convert_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_CONVERT;
}

sub is_exception_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_EXCEPTION;
}

sub is_ite_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_FUNC
      && $self->{value} eq ASTType::ROSE_OP_ITE;
}

sub is_lit_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::EXP_LIT;
}

sub is_vec_index_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_VEC_INDEX;
}

sub is_vec_range_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_VEC_RANGE;
}

sub is_vec_concat_node {
    my ($self) = @_;
    return $self->{type} eq ASTType::LIT_VEC_CONCAT;
}

sub attribute_exists {
    my ( $self, $attr_key ) = @_;
    return exists $self->{attribute}->{$attr_key};
}

sub append_child {
    my ( $self, $child ) = @_;
    push @{ $self->{children} }, $child;
}

sub append_sibling {
    my ( $self, $sibling ) = @_;
    push @{ $self->{siblings} }, $sibling;
}

sub has_attribute {
    my ( $self, $attr_key, $attr_value ) = @_;
    return exists $self->{attributes}{$attr_key};
}

sub add_attribute {
    my ( $self, $attr_key, $attr_value ) = @_;
    $self->{attributes}{$attr_key} = $attr_value;
}

sub get_attribute {
    my ( $self, $attr_key ) = @_;
    die "Unexpected error: Unknown attribute $attr_key"
      unless exists $self->{attributes}{$attr_key};
    return $self->{attributes}{$attr_key};
}

sub get_attributes {
    my ( $self ) = @_;
    return $self->{attributes};
}

sub get_type {
    my ($self) = @_;
    return $self->{type};
}

sub get_value {
    my ($self) = @_;
    return $self->{value};
}

sub get_children {
    my ($self) = @_;
    return $self->{children};
}

sub get_nth_child {
    my ( $self, $index ) = @_;
    die "Unexpected Error: Invalid index $index"
      unless $index >= 0 && $index < scalar @{ $self->{children} };
    return $self->{children}[$index];
}

sub get_siblings {
    my ($self) = @_;
    return $self->{siblings};
}

sub get_nth_sibling {
    my ( $self, $index ) = @_;
    die "Unexpected Error: Invalid index $index"
      unless $index >= 0 && $index < scalar @{ $self->{siblings} };
    return $self->{siblings}[$index];
}

sub set_type {
    my ( $self, $type ) = @_;
    $self->{type} = $type;
}

sub set_value {
    my ( $self, $value ) = @_;
    $self->{value} = $value;
}

sub set_attributes {
    my ( $self, $attrs ) = @_;
    $self->{attributes} = $attrs;
}

sub set_children {
    my ( $self, $children ) = @_;
    $self->{children} = $children;
}

sub set_nth_child {
    my ( $self, $index, $child ) = @_;
    $self->{children}[$index] = $child;
}

sub set_siblings {
    my ($self, $siblings) = @_;
    $self->{siblings} = $siblings;
}

sub set_nth_sibling {
    my ( $self, $index, $sibling ) = @_;
    $self->{siblings}[$index] = $sibling;
}

sub is_type {
    my ( $self, $type ) = @_;
    return $self->{type} eq $type;
}

sub is_op {
    my ( $self, $op ) = @_;
    die "Unexpected Error: Not a function node" unless $self->is_func_node();
    return $self->get_value() eq $op;
}

sub set_node {
    my ( $self, $to_copy ) = @_;
    $self->set_value($to_copy->get_value());
    $self->set_type($to_copy->get_type());
    $self->set_attributes($to_copy->get_attributes());
    $self->set_children($to_copy->get_children());
    $self->set_siblings($to_copy->get_siblings());
}

1;
