version: 0.2


phases:
  build:
    commands:
      - echo "publishing reports"
reports:
  integration-test-reports:
    files:
      - 'report.xml'
    file-format: JunitXml    