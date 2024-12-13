resource "yandex_compute_snapshot_schedule" "daily-snapshot" {
  name = "daily-snapshot"

  schedule_policy {
    expression = "0 0 ? * *"
  }

  snapshot_count = 7

  snapshot_spec {
    description = "daily-snapshot"
  }

  disk_ids = ["${yandex_compute_instance.bastion.boot_disk.0.disk_id}",
    "${yandex_compute_instance.nginx-1.boot_disk.0.disk_id}",
    "${yandex_compute_instance.nginx-2.boot_disk.0.disk_id}",
    "${yandex_compute_instance.zabbix-server.boot_disk.0.disk_id}",
    "${yandex_compute_instance.elastic.boot_disk.0.disk_id}",
  "${yandex_compute_instance.kibana.boot_disk.0.disk_id}", ]
}
