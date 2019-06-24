#!/bin/bash

set -xe

function create_ca_secret {
	cfssl gencert -initca ca-csr.json|cfssljson -bare ca -

	kubectl create secret generic cluster-ca \
			--from-file=ca.pem=ca.pem \
			--from-file=ca-key=ca-key.pem \
			--from-file=ca.csr=ca.csr
}

function create_certificate_secrets {
	if kubectl get secret/cluster-ca ; then
		echo "secret/cluster-ca already exists"
        kubectl get secret cluster-ca -o json | jq -r '.data."ca.pem"' | base64 -d > ca.pem
        kubectl get secret cluster-ca -o json | jq -r '.data."ca-key"' | base64 -d > ca-key.pem
	else
        create_ca_secret
	fi

	if kubectl get secret/cluster-default-ssl ; then
		echo "secret/cluster-default-ssl already exists"
	else
		cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
			  -profile=server default-server-csr.json | cfssljson -bare default-server
		cp default-server.pem default-server-with-chain.pem
		cat ca.pem >> default-server-with-chain.pem

		kubectl create secret generic cluster-default-ssl \
			--from-file=default-server.pem=default-server.pem \
			--from-file=default-server-with-chain.pem=default-server-with-chain.pem \
			--from-file=default-server-key.pem=default-server-key.pem \
			--from-file=default-server.csr=default-server.csr
	fi
}

cd /root/cfssl

if [[ $1 = "install" ]]; then
    create_certificate_secrets

elif [[ $1 = "update" ]]; then
    kubectl delete secret/cluster-ca --namespace=default --ignore-not-found
    kubectl delete secret/cluster-default-ssl --namespace=default --ignore-not-found
    kubectl delete secret/cluster-kube-system-ssl --namespace=default --ignore-not-found
    create_certificate_secrets

elif [[ $1 = "uninstall" ]]; then

	for sname in cluster-ca cluster-default-ssl cluster-kube-system-ssl
	do
		kubectl delete secret $sname --ignore-not-found
	done

else

	echo "Missing argument, should be 'install', 'update' or 'uninstall'"
	exit 1

fi
