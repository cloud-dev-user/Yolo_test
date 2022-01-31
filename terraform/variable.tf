variable "image_id" {
    default = "ami-06ec8443c2a35b0ba" 
}

variable "instance_type" {
    default = "t2.micro"
}

variable "region" {

       default = "eu-central-1"
}

variable "vpc_range" {

        default = "10.161.0.0/24"
}

variable "subnet_range" {

      type = map (object({
                name = string 
           s_cidr_range = string
           s_availability_zone = string 
        }))
      default = {
        "subnet-1a" = {
                name = "subnet-1a"
          s_cidr_range = "10.161.0.0/25"
           s_availability_zone = "eu-central-1a"
          }
          "subnet-1b" = {
                    name = "subnet-1b"
             s_cidr_range = "10.161.0.128/26"
             s_availability_zone = "eu-central-1b"
            }
            "subnet-1c" = {
                     name = "subnet-1c"
               s_cidr_range = "10.161.0.192/26"
               s_availability_zone = "eu-central-1b"
              }
    }
}
variable "key-id" {
           default = "dev-key"
               }
variable "y_ingress" {

      type = map (object({
                 port = string
           y_cidr_range = list(string)
           protocol = string
        }))
      default = {
        "80" = {
                port = "80"
          y_cidr_range = ["0.0.0.0/0"]
           protocol = "tcp"
          }
         "22" = {
                port = "22"
                y_cidr_range = ["0.0.0.0/0"]
                protocol = "tcp"
          }
}
}
