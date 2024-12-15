terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13" 
}
#variable "yandex_cloud_token" {
#  type = string
#  description = "Данная переменная потребует ввести секретный токен в консоли при запуске terraform plan/apply"
#}

provider "yandex" {
  service_account_key_file = "key.json"
#  token     = var.yandex_cloud_token #секретные данные должны быть в сохранности!! Никогда не выкладывайте токен в публичный доступ.
  cloud_id                 = "b1g3n2adbc5nvcl6o29m"
  folder_id                = "b1gbfl7c6hg3333dj4ko"
}

################### Create vm nginx 1 #####################

resource "yandex_compute_instance" "nginx-1" {

  name                      = "nginx-1"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-a"
  hostname                  = "nginx-1"
  
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd82p04mkorgqovbtg3u"
      size     = 8
    }
  }

  network_interface {
    subnet_id          = "${yandex_vpc_subnet.subnet-1.id}"
    nat                = false
    security_group_ids = ["${yandex_vpc_security_group.nginx-sg.id}"]
    ip_address         = "192.168.10.10"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
  
  scheduling_policy {
    preemptible = true
  } 
}



################### Create vm nginx 2 #####################

resource "yandex_compute_instance" "nginx-2" {

  name                      = "nginx-2"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-b"
  hostname                  = "nginx-2"
  
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd82p04mkorgqovbtg3u"
      size     = 8
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-2.id}"
    nat       = false
    security_group_ids = ["${yandex_vpc_security_group.nginx-sg.id}"]
    ip_address         = "192.168.20.10"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }      
}


################### Create vm zabbix server #####################

resource "yandex_compute_instance" "zabbix-server" {

  name                      = "zabbix-server"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-d"
  hostname                  = "zabbix-server"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd80eup4e4h7mmodr9d4"
      size     = 10
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-3.id}"
    nat       = true
    security_group_ids = ["${yandex_vpc_security_group.zabbix-sg.id}"]
    ip_address         = "192.168.30.10"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }      
}


################### Create vm Elasticsearch #####################

resource "yandex_compute_instance" "elastic" {

  name                      = "elastic"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-d"
  hostname                  = "elastic"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd82p04mkorgqovbtg3u"
      size     = 10
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-4.id}"
    nat       = false
    security_group_ids = ["${yandex_vpc_security_group.elastic-sg.id}"]
    ip_address         = "192.168.40.10"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

################### Create vm Kibana #####################

resource "yandex_compute_instance" "kibana" {

  name                      = "kibana"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-d"
  hostname                  = "kibana"
  
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd82p04mkorgqovbtg3u"
      size     = 8
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-3.id}"
    nat       = true
    security_group_ids = ["${yandex_vpc_security_group.kibana-sg.id}"]
    ip_address         = "192.168.30.20"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}


################### Create vm bastion #####################

resource "yandex_compute_instance" "bastion" {

  name                      = "bastion"
  allow_stopping_for_update = true
  platform_id               = "standard-v2"
  zone                      = "ru-central1-d"
  hostname                  = "bastion"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = "fd80eup4e4h7mmodr9d4"
      size     = 8
    }
  }

  network_interface {
    subnet_id          = "${yandex_vpc_subnet.subnet-3.id}"
    nat                = true
    security_group_ids = ["${yandex_vpc_security_group.bastion-sg.id}"]
    ip_address         = "192.168.30.30"
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

################### Creating a network  #####################

resource "yandex_vpc_network" "network-1" {
  name = "network-1"
  
}

################### Creating a gateway  #####################

resource "yandex_vpc_gateway" "nat-gateway" {
  folder_id = "b1gbfl7c6hg3333dj4ko"
  name = "nat"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route-table" {
  name       = "nginx-elastic-route-table"
  network_id = yandex_vpc_network.network-1.id
  static_route {
  destination_prefix = "0.0.0.0/0"
  gateway_id         = yandex_vpc_gateway.nat-gateway.id
  }
}

################ subnet for nginx1 ####################

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet-1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route-table.id
}


################ subnet for nginx2 ####################

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet-2"
  zone           = "ru-central1-b"
  v4_cidr_blocks = ["192.168.20.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
  route_table_id = yandex_vpc_route_table.route-table.id
}

################ subnet for zabbix, kibana, bastion ########

resource "yandex_vpc_subnet" "subnet-3" {
  name           = "subnet-3"
  zone           = "ru-central1-d"
  v4_cidr_blocks = ["192.168.30.0/24"]
  network_id     = yandex_vpc_network.network-1.id
}

################ subnet for elastic ########################

resource "yandex_vpc_subnet" "subnet-4" {
  name = "subnet-4"

  v4_cidr_blocks = ["192.168.40.0/24"]
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-1.id
  route_table_id = yandex_vpc_route_table.route-table.id
}

################### Creating a target group #####################

resource "yandex_alb_target_group" "target-group" {
  name           = "target-group"

  target {
    subnet_id    = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.nginx-1.network_interface.0.ip_address}"
  }

  target {
    subnet_id    = "${yandex_vpc_subnet.subnet-2.id}"
    ip_address   = "${yandex_compute_instance.nginx-2.network_interface.0.ip_address}"
  }
}

################### Creating a backend group #####################

resource "yandex_alb_backend_group" "backend-group" {
  name                     = "backend-group"
  session_affinity {
    connection {
      source_ip = true
    }
  }

  http_backend {
    name                   = "backend-group-1"
    weight                 = 1
    port                   = 80
    target_group_ids       = ["${yandex_alb_target_group.target-group.id}"]
    load_balancing_config {
      panic_threshold      = 90
    }    
    healthcheck {
      timeout              = "2s"
      interval             = "3s"
      healthy_threshold    = 10
      unhealthy_threshold  = 15 
      http_healthcheck {
        path               = "/"
      }
    }
  }
}

################### Creating a router #####################

resource "yandex_alb_http_router" "router" {
  name          = "router"
}

resource "yandex_alb_virtual_host" "nginx-virtual-host" {
  name                    = "nginx-virtual-host"
  http_router_id          = yandex_alb_http_router.router.id
  route {
    name                  = "nginx-route"
    http_route {
      http_route_action {
        backend_group_id  = "${yandex_alb_backend_group.backend-group.id}"
        timeout           = "60s"
      }
    }
  }
}

################### Creating a application load balancer  #####################

resource "yandex_alb_load_balancer" "load-balancer" {
  name               = "nginx-balancer"
  network_id         = "${yandex_vpc_network.network-1.id}"
  security_group_ids = ["${yandex_vpc_security_group.nginx-sg.id}"]

 allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = "${yandex_vpc_subnet.subnet-2.id}"
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = "${yandex_alb_http_router.router.id}"
      }
    }
  }
}


################ security rules for nginx1-2 ###########

resource "yandex_vpc_security_group" "nginx-sg" {
  name        = "nginx-sg"
  description = "rules for nginx1-2"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "HTTP in"
    port           = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    port           = "22"
    v4_cidr_blocks = ["192.168.30.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix"
    port           = "10050"
    v4_cidr_blocks = ["192.168.30.0/24"] 
  }

  ingress {
    description = "Health checks from NLB"
    protocol = "TCP"
    predefined_target = "loadbalancer_healthchecks" 
  }


  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

################ security rules for zabbix ###############

resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix-sg"
  description = "rules for zabbix"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = "8080"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "for ssh bastion"
    port           = "22"
    v4_cidr_blocks = ["192.168.30.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix"
    port           = "10051"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24", "192.168.40.0/24"] 
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

################ security rules for elastic ###############

resource "yandex_vpc_security_group" "elastic-sg" {
  name        = "elastic-sg"
  description = "rules for elastic"
  network_id  = "${yandex_vpc_network.network-1.id}"  


  ingress {
    protocol       = "TCP"
    description    = "for ssh bastion"
    port           = "22"
    v4_cidr_blocks = ["192.168.30.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix"
    port           = "10050"
    v4_cidr_blocks = ["192.168.30.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "filebeat"
    port           = "9200"
    v4_cidr_blocks = ["192.168.10.0/24", "192.168.20.0/24", "192.168.30.0/24"] 
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}

################ security rules for kibana ###################

resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  description = "rules for kibana"
  network_id  = "${yandex_vpc_network.network-1.id}"  

  ingress {
    protocol       = "TCP"
    description    = "kibana"
    port           = "5601"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "for ssh bastion"
    port           = "22"
    v4_cidr_blocks = ["192.168.30.0/24"] 
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix"
    port           = "10050"
    v4_cidr_blocks = ["192.168.30.0/24"] 
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"] 
  }
}
################ security rules for bastion ################

resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "internal-bastion-sg"
  description = "open ssh"
  network_id  = "${yandex_vpc_network.network-1.id}"  
  ingress {
      protocol          = "TCP"
      description       = "ssh"
      port              = 22
      v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      protocol          = "ANY"
      description       = "any for basion to out"
      from_port         = 0
      to_port           = 65535
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
}


output "external_ip_address_bastion" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "external_ip_address_kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "external_ip_address_zabbix" {
  value = yandex_compute_instance.zabbix-server.network_interface.0.nat_ip_address
}

