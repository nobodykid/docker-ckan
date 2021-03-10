###################
### Extensions ####
###################
FROM keitaro/ckan:2.9.1 as extbuild

# Switch to the root user
USER root

# Install any system packages necessary to build extensions
RUN apk add --no-cache python3-dev

# Locations and tags of additional CKAN extensions
ENV DISQUS_GIT_URL=https://github.com/keitaroinc/ckanext-disqus
ENV DISQUS_GIT_BRANCH=ckan-2.9

# Fetch and build the custom CKAN extensions
RUN pip wheel --wheel-dir=/wheels git+${DISQUS_GIT_URL}@${DISQUS_GIT_BRANCH}#egg=ckanext-disqus

############
### MAIN ###
############
FROM keitaro/ckan:2.9.1

# Add the custom extensions to the plugins list
ENV CKAN__PLUGINS envvars image_view text_view recline_view datastore datapusher disqus

# Switch to the root user
USER root

COPY --from=extbuild /wheels /srv/app/ext_wheels

# Install and enable the custom extensions
RUN pip install --no-index --find-links=/srv/app/ext_wheels ckanext-disqus && \
    ckan config-tool ${APP_DIR}/production.ini "ckan.plugins = ${CKAN__PLUGINS}" && \
    chown -R ckan:ckan /srv/app

# Remove wheels
RUN rm -rf /srv/app/ext_wheels

# Switch to the ckan user
USER ckan
