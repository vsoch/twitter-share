FROM vanessa/boxes

# docker build -t vanessa/share-tweet:image

LABEL "com.github.actions.name"="Share Tweet Button"
LABEL "com.github.actions.description"="Provides the user with a tweet to share a merged image."
LABEL "com.github.actions.icon"="share"
LABEL "com.github.actions.color"="blue"

COPY share.sh /share.sh
COPY /post_message.py /post_message.py

RUN chmod u+x /share.sh && \
    chmod u+x /post_message.py
ENTRYPOINT ["/share.sh"]
