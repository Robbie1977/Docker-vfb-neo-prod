FROM openjdk:8-jdk

RUN apt-get update --quiet --quiet \
    && apt-get install --quiet --quiet --no-install-recommends lsof \
    && apt-get install --quiet --quiet --no-install-recommends git maven pigz python-psycopg2 \
    && rm -rf /var/lib/apt/lists/*

RUN export workspace=/opt && cd "${WORKSPACE}" && \
echo '** Git checkout owltools **' && \
git clone https://github.com/owlcollab/owltools.git && \
cd owltools/OWLTools-Parent && \
mvn -Dgpg.passphrase=default99 -DskipTests=true -Dmaven.javadoc.skip=true -Dsource.skip=true clean package

RUN export workspace=/opt && cd "${WORKSPACE}" && \
echo '** Git checkout Brain **' && \
git clone https://github.com/hdietze/Brain.git && \
cd Brain && \
mvn -Dgpg.passphrase=default99 -DskipTests=true -Dmaven.javadoc.skip=true -Dsource.skip=true clean package

RUN export workspace=/opt && cd "${WORKSPACE}" && \
echo '** Git checkout OLS_configs **' && \
git clone https://github.com/VirtualFlyBrain/OLS_configs.git && \
echo '** Git checkout VFB_neo4j **' && \
git clone https://github.com/VirtualFlyBrain/VFB_neo4j.git && \
echo '** Git checkout VFB_owl **' && \
git clone https://github.com/VirtualFlyBrain/VFB_owl.git && \
cd VFB_owl && \
find . -name '*.gz' -exec pigz -dvf '{}' \; && \
mvn clean package

VOLUME /data

RUN mkdir -p $HOME/.neo4j/ && \
ls -s /data $HOME/.neo4j/data

RUN echo '** Build OLS **' && \
export workspace=/opt && cd "${WORKSPACE}" && \
git clone https://github.com/EBISPOT/OLS.git && \
cp OLS_configs/*.properties OLS/ols-apps/ols-neo4j-app/src/main/resources/ && \
cd OLS && \
mvn clean package

RUN export workspace=/opt && \
echo '** loading vfb to OLS **' && \
java -Xmx2g -jar -Dspring.profiles.active=vfb -Dols.home=${WORKSPACE} ols-apps/ols-neo4j-app/target/ols-neo4j-app.jar

ENTRYPOINT ["java -Xmx2g -jar -Dspring.profiles.active=vfb -Dols.home=/opt /opt/ols-apps/ols-neo4j-app/target/ols-neo4j-app.jar"]


