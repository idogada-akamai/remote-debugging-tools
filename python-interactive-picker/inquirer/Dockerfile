FROM python:3.11.2-alpine3.17
RUN python -m pip install inquirer
WORKDIR /app
COPY main.py main.py
ENTRYPOINT [ "python", "/app/main.py" ]
