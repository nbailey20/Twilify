resource "aws_vpc" "vpc" {
  cidr_block       = "10.41.0.0/24"
  tags = {
    Name = "tmf-vpc"
  }
}

resource "aws_subnet" "privateSubnet1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.41.0.128/26"
  availability_zone = "us-east-1a"
  tags = {
    Name = "tmf-private-subnet-1"
  }
}

resource "aws_subnet" "privateSubnet2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.41.0.192/26"
  availability_zone = "us-east-1b"
  tags = {
    Name = "tmf-private-subnet-2"
  }
}

resource "aws_subnet" "publicSubnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.41.0.0/25"
  availability_zone = "us-east-1c"
  tags = {
    Name = "tmf-public-subnet"
  }
}

resource "aws_route_table" "privateRt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tmf-private-rt"
  }
}

resource "aws_route_table" "publicRt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "tmf-public-rt"
  }
}

resource "aws_route_table_association" "privateRtAssociation1" {
  subnet_id      = aws_subnet.privateSubnet1.id
  route_table_id = aws_route_table.privateRt.id
}

resource "aws_route_table_association" "privateRtAssociation2" {
  subnet_id      = aws_subnet.privateSubnet2.id
  route_table_id = aws_route_table.privateRt.id
}

resource "aws_route_table_association" "publicRtAssociation" {
  subnet_id      = aws_subnet.publicSubnet.id
  route_table_id = aws_route_table.publicRt.id
}
