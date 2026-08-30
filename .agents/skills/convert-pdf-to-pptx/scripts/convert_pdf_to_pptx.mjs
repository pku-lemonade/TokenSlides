#!/usr/bin/env node

import { spawn } from "node:child_process";
import { constants as fsConstants } from "node:fs";
import fs from "node:fs/promises";
import { createRequire } from "node:module";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { pathToFileURL } from "node:url";

function usage() {
  return `Usage:
  convert_pdf_to_pptx.mjs --input INPUT.pdf --output OUTPUT.pptx [options]

Options:
  --mode png|svg                 Page artwork format (default: png)
  --dpi NUMBER                   PNG render resolution (default: 300)
  --mixed-page-policy error|contain
                                  Reject mixed aspect ratios or letterbox them
                                  (default: error)
  --work-dir PATH                Keep intermediates under this directory
  --keep-work                    Preserve the generated page artwork
  --force                        Replace an existing output file
  --help                         Show this help`;
}

function parseArgs(argv) {
  const args = {
    mode: "png",
    dpi: 300,
    mixedPagePolicy: "error",
    force: false,
    keepWork: false,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    const value = () => {
      index += 1;
      if (index >= argv.length) {
        throw new Error(`Missing value for ${token}`);
      }
      return argv[index];
    };

    if (token === "--input") args.input = value();
    else if (token === "--output") args.output = value();
    else if (token === "--mode") args.mode = value();
    else if (token === "--dpi") args.dpi = Number(value());
    else if (token === "--mixed-page-policy") args.mixedPagePolicy = value();
    else if (token === "--work-dir") args.workDir = value();
    else if (token === "--force") args.force = true;
    else if (token === "--keep-work") args.keepWork = true;
    else if (token === "--help" || token === "-h") args.help = true;
    else throw new Error(`Unknown option: ${token}`);
  }

  if (args.help) return args;
  if (!args.input || !args.output) {
    throw new Error("Both --input and --output are required");
  }
  if (!new Set(["png", "svg"]).has(args.mode)) {
    throw new Error("--mode must be png or svg");
  }
  if (!Number.isFinite(args.dpi) || args.dpi < 72 || args.dpi > 600) {
    throw new Error("--dpi must be between 72 and 600");
  }
  if (!new Set(["error", "contain"]).has(args.mixedPagePolicy)) {
    throw new Error("--mixed-page-policy must be error or contain");
  }
  return args;
}

async function canExecute(candidate) {
  try {
    await fs.access(candidate, fsConstants.X_OK);
    return true;
  } catch {
    return false;
  }
}

async function resolveTool(name, envName) {
  const explicit = process.env[envName];
  if (explicit) {
    if (!(await canExecute(explicit))) {
      throw new Error(`${envName} is not executable: ${explicit}`);
    }
    return explicit;
  }

  if (process.env.RUNTIME_BIN_DIR) {
    const bundled = path.join(process.env.RUNTIME_BIN_DIR, name);
    if (await canExecute(bundled)) return bundled;
  }
  return name;
}

function run(command, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) resolve({ stdout, stderr });
      else reject(new Error(`${command} exited with ${code}\n${stderr || stdout}`));
    });
  });
}

async function loadArtifactTool() {
  const modulesRoot = process.env.RUNTIME_NODE_MODULES;
  if (!modulesRoot) {
    throw new Error("RUNTIME_NODE_MODULES is required; load workspace dependencies first");
  }
  const runtimeRequire = createRequire(path.join(path.dirname(modulesRoot), "codex-runtime-loader.cjs"));
  const entry = runtimeRequire.resolve("@oai/artifact-tool");
  return import(pathToFileURL(entry).href);
}

function parsePageCount(output) {
  const match = output.match(/^Pages:\s+(\d+)\s*$/m);
  if (!match) throw new Error("Could not read the PDF page count from pdfinfo");
  return Number(match[1]);
}

function parsePageGeometry(output, expectedCount) {
  const pages = new Map();
  const sizePattern = /^Page\s+(\d+)\s+size:\s+([\d.]+)\s+x\s+([\d.]+)\s+pts\s*$/gm;
  const rotationPattern = /^Page\s+(\d+)\s+rot:\s+(-?\d+)\s*$/gm;

  for (const match of output.matchAll(sizePattern)) {
    pages.set(Number(match[1]), {
      page: Number(match[1]),
      widthPt: Number(match[2]),
      heightPt: Number(match[3]),
      rotation: 0,
    });
  }
  for (const match of output.matchAll(rotationPattern)) {
    const page = pages.get(Number(match[1]));
    if (page) page.rotation = Number(match[2]);
  }

  if (pages.size !== expectedCount) {
    throw new Error(`Expected geometry for ${expectedCount} pages, found ${pages.size}`);
  }
  return [...pages.values()].sort((a, b) => a.page - b.page);
}

function pageAspect(page) {
  return page.widthPt / page.heightPt;
}

function hasMixedAspects(pages) {
  const first = pageAspect(pages[0]);
  return pages.some((page) => Math.abs(pageAspect(page) / first - 1) > 0.001);
}

function containedFrame(slideWidth, slideHeight, page) {
  const pageWidth = page.widthPt * (96 / 72);
  const pageHeight = page.heightPt * (96 / 72);
  const scale = Math.min(slideWidth / pageWidth, slideHeight / pageHeight);
  const width = pageWidth * scale;
  const height = pageHeight * scale;
  return {
    left: (slideWidth - width) / 2,
    top: (slideHeight - height) / 2,
    width,
    height,
  };
}

function pageNumberFromName(fileName) {
  const match = fileName.match(/-(\d+)\.(?:png|svg)$/i);
  return match ? Number(match[1]) : Number.NaN;
}

async function renderPages({ input, workDir, mode, dpi, pageCount, pdftocairo }) {
  if (mode === "png") {
    const prefix = path.join(workDir, "page");
    await run(pdftocairo, ["-png", "-cropbox", "-r", String(dpi), input, prefix]);
    const files = (await fs.readdir(workDir))
      .filter((name) => /^page-\d+\.png$/i.test(name))
      .sort((a, b) => pageNumberFromName(a) - pageNumberFromName(b))
      .map((name) => path.join(workDir, name));
    if (files.length !== pageCount) {
      throw new Error(`Expected ${pageCount} PNG pages, found ${files.length}`);
    }
    return files;
  }

  const files = [];
  const digits = String(pageCount).length;
  for (let page = 1; page <= pageCount; page += 1) {
    const output = path.join(workDir, `page-${String(page).padStart(digits, "0")}.svg`);
    await run(pdftocairo, ["-svg", "-f", String(page), "-l", String(page), input, output]);
    await fs.access(output);
    files.push(output);
  }
  return files;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(usage());
    return;
  }

  const input = path.resolve(args.input);
  const output = path.resolve(args.output);
  await fs.access(input);
  if (path.extname(input).toLowerCase() !== ".pdf") {
    throw new Error(`Input must be a PDF: ${input}`);
  }
  if (path.extname(output).toLowerCase() !== ".pptx") {
    throw new Error(`Output must end in .pptx: ${output}`);
  }
  if (!args.force) {
    try {
      await fs.access(output);
      throw new Error(`Output already exists; choose another path or pass --force: ${output}`);
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }

  const pdfinfo = await resolveTool("pdfinfo", "PDFINFO_BIN");
  const pdftocairo = await resolveTool("pdftocairo", "PDFTOCAIRO_BIN");
  const basicInfo = await run(pdfinfo, [input]);
  const pageCount = parsePageCount(basicInfo.stdout);
  const detailedInfo = await run(pdfinfo, ["-f", "1", "-l", String(pageCount), "-box", input]);
  const pages = parsePageGeometry(detailedInfo.stdout, pageCount);

  if (hasMixedAspects(pages) && args.mixedPagePolicy === "error") {
    throw new Error("The PDF contains mixed page aspect ratios; use --mixed-page-policy contain to letterbox them");
  }

  const ownWorkDir = !args.workDir;
  const workDir = args.workDir
    ? path.resolve(args.workDir)
    : await fs.mkdtemp(path.join(os.tmpdir(), "pdf-to-pptx-"));
  await fs.mkdir(workDir, { recursive: true });
  await fs.mkdir(path.dirname(output), { recursive: true });
  const temporaryOutput = path.join(
    path.dirname(output),
    `.${path.basename(output, ".pptx")}.${process.pid}.tmp.pptx`,
  );
  const inspectSidecar = `${temporaryOutput}.inspect.ndjson`;

  try {
    const pageArtwork = await renderPages({
      input,
      workDir,
      mode: args.mode,
      dpi: args.dpi,
      pageCount,
      pdftocairo,
    });
    const { FileBlob, Presentation, PresentationFile } = await loadArtifactTool();
    const slideWidth = pages[0].widthPt * (96 / 72);
    const slideHeight = pages[0].heightPt * (96 / 72);
    const presentation = Presentation.create({
      slideSize: { width: slideWidth, height: slideHeight },
    });

    for (let index = 0; index < pages.length; index += 1) {
      const slide = presentation.slides.add();
      slide.background.fill = "white";
      const frame = containedFrame(slideWidth, slideHeight, pages[index]);
      const common = {
        alt: `Source PDF page ${index + 1}`,
        fit: "contain",
        position: frame,
      };
      const source = args.mode === "svg"
        ? { svg: await fs.readFile(pageArtwork[index], "utf8") }
        : {
            blob: new Uint8Array(await fs.readFile(pageArtwork[index])),
            contentType: "image/png",
          };
      const image = slide.images.add({ ...common, ...source });
      image.lockAspectRatio = true;
    }

    const pptx = await PresentationFile.exportPptx(presentation);
    await pptx.save(temporaryOutput);
    const imported = await PresentationFile.importPptx(await FileBlob.load(temporaryOutput));
    if (imported.slides.items.length !== pageCount) {
      throw new Error(`PPTX re-import found ${imported.slides.items.length} slides, expected ${pageCount}`);
    }
    for (let index = 0; index < imported.slides.items.length; index += 1) {
      const importedSlide = imported.slides.items[index];
      if (importedSlide.images.items.length !== 1 || importedSlide.shapes.items.length !== 0) {
        throw new Error(`PPTX slide ${index + 1} is not exactly one flattened page image`);
      }
      const actual = importedSlide.images.items[0].frame;
      const expected = containedFrame(slideWidth, slideHeight, pages[index]);
      const frameKeys = ["left", "top", "width", "height"];
      if (frameKeys.some((key) => Math.abs(actual[key] - expected[key]) > 0.1)) {
        throw new Error(`PPTX slide ${index + 1} page image shifted during export`);
      }
    }
    if (args.force) await fs.rm(output, { force: true });
    await fs.rename(temporaryOutput, output);

    const result = {
      input,
      output,
      pageCount,
      mode: args.mode,
      dpi: args.mode === "png" ? args.dpi : null,
      slideSizePx: { width: slideWidth, height: slideHeight },
      mixedPagePolicy: args.mixedPagePolicy,
      workDir: args.keepWork ? workDir : null,
    };
    console.log(JSON.stringify(result, null, 2));
  } finally {
    await fs.rm(temporaryOutput, { force: true });
    await fs.rm(inspectSidecar, { force: true });
    if (ownWorkDir && !args.keepWork) {
      await fs.rm(workDir, { recursive: true, force: true });
    }
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exitCode = 1;
});
