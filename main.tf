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

  #This will install Jenkins Docker container on the instance
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y install apt-transport-https dirmngr",
      "sudo sh -c \"echo 'deb https://apt.dockerproject.org/repo debian-stretch main' >> /etc/apt/sources.list\"",
      "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys F76221572C52609D",
      "sudo apt-get -y update",
      "sudo apt-get -y install docker-engine",
      "sudo docker pull jenkins/jenkins:lts",
      "sudo docker run -e JAVA_OPTS='-Djenkins.install.runSetupWizard=false' --name jenkins -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts"
    ]

    connection {
	  type     = "ssh"
	  user     = "luiledez"
	  private_key = "${file("/Users/luiledez/.ssh/luiledez.local")}"
	}
  }

  provisioner "file" {
    source = "jenkins"
    destination = "/tmp/jenkins"

    connection {
	  type     = "ssh"
	  user     = "luiledez"
	  private_key = "${file("/Users/luiledez/.ssh/luiledez.local")}"
	}
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rsync -avh /tmp/jenkins/* /var/lib/docker/volumes/jenkins_home/_data/",
      "sudo docker container restart jenkins"
    ]

    connection {
	  type     = "ssh"
	  user     = "luiledez"
	  private_key = "${file("/Users/luiledez/.ssh/luiledez.local")}"
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
	  type     = "ssh"
	  user     = "luiledez"
	  private_key = "${file("/Users/luiledez/.ssh/luiledez.local")}"
	}
  }

  #This will deploy application for the first time
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y install apt-transport-https dirmngr",
      "sudo sh -c \"echo 'deb https://apt.dockerproject.org/repo debian-stretch main' >> /etc/apt/sources.list\"",
      "sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys F76221572C52609D",
      "sudo apt-get -y update",
      "sudo apt-get -y install docker-engine",
      "sudo mkdir /data",
      "cd /data",
      "sudo git clone https://github.com/luis-ledezma/timeoff-management",
      "cd timeoff-management",
      "sudo docker build -t timeoff .",
      "sudo docker run -d -it -p 80:3000 --name timeoff-app timeoff npm start"
    ]

    connection {
	  type     = "ssh"
	  user     = "luiledez"
	  private_key = "${file("/Users/luiledez/.ssh/luiledez.local")}"
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