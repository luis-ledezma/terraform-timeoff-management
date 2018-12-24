#Setting up connection variables
variable "connection_type" {
  default = "ssh"
}
variable "connection_user" {
  default = "luiledez"
}
variable "connection_private_key" {
  default = "/Users/luiledez/.ssh/luiledez.local"
}

#Setting up our provider as Google Cloud Platform
provider "google" {
  project = "gorilla-challenge"
  region  = "us-east1"
  zone    = "us-east1-b"
}

#Creating our Jenkins instance
resource "google_compute_instance" "jenkins_instance" {
  name         = "jenkins-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # Setting up our previously created network
    network = "${google_compute_network.vpc_network.self_link}"
    access_config = {
    }
  }

  provisioner "file" {
    source = "jenkins"
    destination = "/tmp/jenkins"

    connection {
      type = "${var.connection_type}"
	  user = "${var.connection_user}"
	  private_key = "${file(var.connection_private_key)}"
    }
  }

  provisioner "file" {
    source = "utils/install-docker.sh"
    destination = "/tmp/install-docker.sh"

    connection {
      type = "${var.connection_type}"
	  user = "${var.connection_user}"
	  private_key = "${file(var.connection_private_key)}"
    }
  }

  #This will install Jenkins Docker container on the instance
  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/install-docker.sh",
      "sudo docker build -t jenkins-custom /tmp/jenkins",
      "sudo docker run --name jenkins -d -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -p 8080:8080 -p 50000:50000 jenkins-custom",
      "sudo rsync -avh /tmp/jenkins/* /var/lib/docker/volumes/jenkins_home/_data/",
      "sudo docker container restart jenkins"
    ]

    connection {
      type = "${var.connection_type}"
	  user = "${var.connection_user}"
	  private_key = "${file(var.connection_private_key)}"
    }
  }
}

#Creating the application instance
resource "google_compute_instance" "app_instance" {
  name         = "app-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # Setting up our previously created network
    network = "${google_compute_network.vpc_network.self_link}"
    access_config = {
    }
  }

  #Putting the deployment script on the server
  provisioner "file" {
    source = "app"
    destination = "~/app"

    connection {
      type = "${var.connection_type}"
	  user = "${var.connection_user}"
	  private_key = "${file(var.connection_private_key)}"
    }
  }

  provisioner "file" {
    source = "utils/install-docker.sh"
    destination = "/tmp/install-docker.sh"

    connection {
      type = "${var.connection_type}"
	  user = "${var.connection_user}"
	  private_key = "${file(var.connection_private_key)}"
    }
  }

  #This will deploy application for the first time
  provisioner "remote-exec" {
    inline = [
      "sudo bash /tmp/install-docker.sh",
      "sudo mkdir /data",
      "cd /data",
      "sudo git clone https://github.com/luis-ledezma/timeoff-management",
      "cd timeoff-management",
      "sudo docker build -t timeoff .",
      "sudo docker run -d -it -p 80:3000 --name timeoff-app timeoff npm start"
    ]

    connection {
      type = "${var.connection_type}"
	  user = "${var.connection_user}"
	  private_key = "${file(var.connection_private_key)}"
    }
  }
}

#Allowing ssh for the network
resource "google_compute_firewall" "default" {
  name    = "allow-ping-ssh-web"
  network = "${google_compute_network.vpc_network.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000", "22", "3000"]
  }

}

#Creating a network
resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}