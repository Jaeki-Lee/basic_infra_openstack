# Volume
resource "openstack_blockstorage_volume_v3" "volumes" {
    for_each = toset(var.volume_names)
    region = "RegionOne"
    name = each.value
    size = var.volume_size
    image_id = var.image_id
}
