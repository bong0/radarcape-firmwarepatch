Installation procedure from Debian401Writer


    rm /var/lib/apt/lists/*
    apt-get update
    apt-get -y install locales
    apt-get upgrade -y

    cat <<EOF > /etc/default/locale 
    LC_ALL=en_US.UTF-8
    LANG=en_US.UTF-8
    LANGUAGE=en_US.UTF-8
    EOF

    sed -i '/^#.*en_US.UTF-8/s/^#//' /etc/locale.gen
    locale-gen
