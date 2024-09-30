if [[ -n $SSH_CONNECTION ]] ; then
    echo "I am logged in remotely"
    tidal-dl
fi
