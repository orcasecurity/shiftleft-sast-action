const core = require("@actions/core");

function getDetail(control) {
  let details = wrapWords(control["details"]);
  let message = `Details:\n${details}`;
  let recommendation = control["recommendation"];
  if (recommendation) {
    recommendation = wrapWords(recommendation);
    message = `${message}\n\nRecommendation:\n${recommendation}`;
  }

  const sastParams = getSastParams(control);
  if (sastParams) {
    message = `${message}\n\n${sastParams}`;
  }

  return message;
}

function getSastParams(control) {
  const { impact, likelihood, confidence } = control;

  const messages = [];
  impact && messages.push(`Impact: ${impact}`);
  likelihood && messages.push(`Likelihood: ${likelihood}`);
  confidence && messages.push(`Confidence: ${confidence}`);

  if(messages.length === 0) {
    return undefined;
  }

  return messages.join(' | ');
}

function wrapWords(input, maxLineLength = 80) {
  const words = input.split(/\s+/);
  const lines = [];
  let currentLine = "";

  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    if (currentLine.length + word.length > maxLineLength) {
      lines.push(currentLine.trim());
      currentLine = "";
    }
    currentLine += (currentLine ? " " : "") + word;
  }

  if (currentLine) {
    lines.push(currentLine.trim());
  }

  return lines.join("\n");
}

function extractAnnotations(results) {
  let annotations = [];
  for (const controlResults of results.results || []) {
    for (const finding of controlResults["findings"]) {
      const catalogControl = controlResults["catalog_control"];
      annotations.push({
        file: finding["file_name"],
        startLine: finding["position"]["start_line"],
        endLine: finding["position"]["end_line"],
        priority: finding["priority"],
        status: finding["status"],
        title: catalogControl["title"],
        details: getDetail(catalogControl, finding),
      });
    }
  }
  return annotations;
}

function annotateChangesWithResults(results) {
  const annotations = extractAnnotations(results);
  annotations.forEach((annotation) => {
    let annotationProperties = {
      title: `[${annotation.priority}] ${annotation.title}`,
      startLine: annotation.startLine,
      endLine: annotation.endLine,
      file: annotation.file,
    };
    if (annotation.status === "FAILED") {
      core.error(annotation.details, annotationProperties);
    } else {
      core.warning(annotation.details, annotationProperties);
    }
  });
}

module.exports = {
  annotateChangesWithResults,
};
