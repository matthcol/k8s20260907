FROM python:3.13-slim

WORKDIR /usr/src

COPY src/requirements.txt .
RUN pip install -r requirements.txt

COPY src .

ENV DB_URL=''
ENV DB_CREATE_TABLES='false'

EXPOSE 8080

CMD [ "uvicorn", "movieapi.main:app", "--host", "0.0.0.0", "--port", "8080" ]