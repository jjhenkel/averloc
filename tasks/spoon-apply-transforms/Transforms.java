import java.io.*;
import java.util.*;
import java.util.regex.*;
import java.util.stream.*;
import java.util.zip.GZIPInputStream;
import java.lang.Thread;
import java.nio.file.Paths;
import java.nio.file.Path;
import java.nio.file.Files;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService; 
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

import transforms.*;

import com.google.gson.*;

import spoon.Launcher;
import spoon.reflect.cu.*;
import spoon.reflect.CtModel;
import spoon.reflect.cu.position.*;
import spoon.reflect.code.*;
import spoon.reflect.declaration.*;
import spoon.reflect.reference.*;

import spoon.OutputType;
import spoon.processing.AbstractProcessor;
import spoon.support.JavaOutputProcessor;
import spoon.support.compiler.VirtualFile;
import spoon.reflect.visitor.filter.TypeFilter;
import spoon.reflect.visitor.DefaultJavaPrettyPrinter;
import spoon.reflect.visitor.PrettyPrinter;

class TransformFileTask implements Runnable {	
	static AtomicInteger counter = new AtomicInteger(0); // a global counter

	String split;
	ArrayList<VirtualFile> inputs;
	ArrayList<String> topTargetSubtokens;

	TransformFileTask(String split, ArrayList<VirtualFile> inputs, ArrayList<String> topTargetSubtokens) {
		this.split = split;
		this.inputs = inputs;
		this.topTargetSubtokens = (ArrayList<String>)topTargetSubtokens.clone();
	}

	private Launcher buildLauncher(AverlocTransformer transformer) {
		Launcher launcher = new Launcher();
			
		// Don't qualify (implicitly qualified) names
		launcher.getEnvironment().setPrettyPrinterCreator(() -> {
			DefaultJavaPrettyPrinter printer = new DefaultJavaPrettyPrinter(launcher.getEnvironment());
			printer.setIgnoreImplicit(false);
			return printer;
		});

		launcher.getEnvironment().setCopyResources(false);
		launcher.getEnvironment().setNoClasspath(true);
		launcher.getEnvironment().setShouldCompile(false);
		launcher.getEnvironment().setOutputType(OutputType.NO_OUTPUT);

		launcher.addProcessor(transformer);

		launcher.setSourceOutputDirectory(
			String.format("/mnt/raw-outputs/%s/%s", split, transformer.getClass().getName())
		);

		return launcher;
	}

	public void run() {
		ArrayList<AverlocTransformer> transformers = new ArrayList<AverlocTransformer>();

		InsertPrintStatements insertPrintStatements = new InsertPrintStatements();
		RenameFields renameFields = new RenameFields();
		RenameLocalVariables renameLocalVariables = new RenameLocalVariables();
		RenameParameters renameParameters = new RenameParameters();
		ReplaceTrueFalse replaceTrueFalse = new ReplaceTrueFalse();

		insertPrintStatements.setTopTargetSubtokens(
			(ArrayList<String>)topTargetSubtokens.clone()
		);
		renameFields.setTopTargetSubtokens(
			(ArrayList<String>)topTargetSubtokens.clone()
		);
		renameLocalVariables.setTopTargetSubtokens(
			(ArrayList<String>)topTargetSubtokens.clone()
		);
		renameParameters.setTopTargetSubtokens(
			(ArrayList<String>)topTargetSubtokens.clone()
		);

		transformers.add(insertPrintStatements);
		transformers.add(renameFields);
		transformers.add(renameLocalVariables);
		transformers.add(renameParameters);
		transformers.add(replaceTrueFalse);
		transformers.add(new Identity());


		for (AverlocTransformer transformer : transformers) {
			try{
				Launcher launcher = buildLauncher(transformer);

				PrettyPrinter printer = launcher.getFactory().getEnvironment().createPrettyPrinter();

				for (VirtualFile input : inputs) {
					launcher.addInputResource(input);
				}

				CtModel model = launcher.buildModel();
				model.processWith(transformer);

				for (CtClass outputClass : model.getElements(new TypeFilter<>(CtClass.class))) {
					if (transformer.changes(outputClass.getSimpleName())) {
						CompilationUnit cu = launcher.getFactory().CompilationUnit().getOrCreate(outputClass);
						List<CtType<?>> toBePrinted = new ArrayList<>();
						toBePrinted.add(outputClass);

						printer.calculate(cu, toBePrinted);

						Path path = Paths.get(
							String.format(
								"/mnt/raw-outputs/%s/%s/%s.java",
								split,
								transformer.getClass().getName(),
								outputClass.getSimpleName().replace("WRAPPER_", "")
							)
						);

						if (!path.getParent().toFile().exists()) {
							path.getParent().toFile().mkdirs();
						}

						File file = path.toFile();
						file.createNewFile();

						// print type
						try (PrintStream stream = new PrintStream(file)) {
							stream.print(printer.getResult());
						}
					}
				}
			} catch (Exception ex1) {
				for (VirtualFile singleInput : inputs) {
					try {
						Launcher launcher = buildLauncher(transformer);
						
						PrettyPrinter printer = launcher.getFactory().getEnvironment().createPrettyPrinter();

						launcher.addInputResource(singleInput);
		
						CtModel model = launcher.buildModel();
						model.processWith(transformer);
		
						for (CtClass outputClass : model.getElements(new TypeFilter<>(CtClass.class))) {
							if (transformer.changes(outputClass.getSimpleName())) {
								CompilationUnit cu = launcher.getFactory().CompilationUnit().getOrCreate(outputClass);
								List<CtType<?>> toBePrinted = new ArrayList<>();
								toBePrinted.add(outputClass);

								printer.calculate(cu, toBePrinted);

								Path path = Paths.get(
									String.format(
										"/mnt/raw-outputs/%s/%s/%s.java",
										split,
										transformer.getClass().getName(),
										outputClass.getSimpleName().replace("WRAPPER_", "")
									)
								);

								if (!path.getParent().toFile().exists()) {
									path.getParent().toFile().mkdirs();
								}

								File file = path.toFile();
								file.createNewFile();

								// print type
								try (PrintStream stream = new PrintStream(file)) {
									stream.print(printer.getResult());
								}
							}
						}
					} catch (Exception ex2) {
						ex1.printStackTrace(System.out);
						ex2.printStackTrace(System.out);
						System.out.println(
							String.format(
								"        * Failed to build model for: %s",
								singleInput.getName()
							)
						);
						return;
					}
				}
			}
		}

		int finished = counter.incrementAndGet();
		System.out.println(String.format("        + Tasks finished: %s", finished));
	}
}

public class Transforms {
	final static int TARGET_SUBTOKENS_LIMIT = 100;
	static ArrayList<String> BANNED_SHAS = new ArrayList<String>(
		Arrays.asList(
			// Don't compile under spoon but pass our other validation...
			"b0b5376a49caa97297fb356899da9b5963f0e9792baf844d0cffa02c0dbc54e1",
			"c1553011c7f6962f2bd9aba2206d9daec4383f05498a44e0ad4aa5996cbebd20",
			"355201a2dd1cb50c5aa0acfe2056b8eb0fb7f5859b74ee1d6669e3868d0f78b8",
			"3f863ba944ce351742b95406d6b1c90f766a66186e13e475ef072e563e32bfbe"
		)
	); 
	
	private static Callable<Void> toCallable(final Runnable runnable) {
    return new Callable<Void>() {
        @Override
        public Void call() {
            runnable.run();
            return null;
        }
    };
	} 
	
	private static <T> ArrayList<ArrayList<T>> chopped(ArrayList<T> list, final int L) {
    ArrayList<ArrayList<T>> parts = new ArrayList<ArrayList<T>>();
    final int N = list.size();
    for (int i = 0; i < N; i += L) {
        parts.add(new ArrayList<T>(
            list.subList(i, Math.min(N, i + L)))
        );
    }
    return parts;
  }

	private static ArrayList<Callable<Void>> makeTasks(String split) {
		try {
			// Return list of tasks
			ArrayList<Callable<Void>> tasks = new ArrayList<Callable<Void>>();
			ArrayList<String> topTargetSubtokens = new ArrayList<String>();
		
			// Load the top tokens once
			try (Stream<String> lines = Files.lines(Paths.get(String.format("/mnt/inputs/%s.targets.histo.txt", split)))) {
				topTargetSubtokens = new ArrayList<String>(
					lines.limit(TARGET_SUBTOKENS_LIMIT).collect(Collectors.toList())
				);
			} catch (IOException ex) {
				ex.printStackTrace();
				System.out.println(ex.toString());
			}

			// The file this thread will read from
			InputStream fileStream = new FileInputStream(String.format(
				"/mnt/inputs/%s.jsonl.gz",
				split
			));

			// File (gzipped) -> Decoded Stream -> Lines
			InputStream gzipStream = new GZIPInputStream(fileStream);
			Reader decoder = new InputStreamReader(gzipStream, "UTF-8");
			BufferedReader buffered = new BufferedReader(decoder);

			// From gzip, create virtual files
			String line;
			JsonParser parser = new JsonParser();
			ArrayList<VirtualFile> inputs = new ArrayList<VirtualFile>();
			while ((line = buffered.readLine()) != null) {
				JsonObject asJson = parser.parse(line).getAsJsonObject();

				if (BANNED_SHAS.contains(asJson.get("sha256_hash").getAsString())) {
					continue;
				}

				inputs.add(new VirtualFile(
					asJson.get("source_code").getAsString().replace(
						"class WRAPPER {",
						String.format(
							"class WRAPPER_%s {",
							asJson.get("sha256_hash").getAsString()
						)
					),
					String.format("%s.java", asJson.get("sha256_hash").getAsString())
				));
			}

			for (ArrayList<VirtualFile> chunk : chopped(inputs, 1000)) {
				tasks.add(toCallable(new TransformFileTask(split, chunk, topTargetSubtokens)));
			}

			return tasks;
		}
		catch (Exception ex) {
			ex.printStackTrace();
			System.out.println(ex.toString());
			return new ArrayList<Callable<Void>>();
		}
	}

	public static void main(String[] args) {
		try {
			ArrayList<Callable<Void>> allTasks = new ArrayList<Callable<Void>>();

			System.out.println("Populating tasks...");
			System.out.println("   - Adding from test split...");
			allTasks.addAll(Transforms.makeTasks("test"));
			System.out.println(String.format("     + Now have %s tasks...", allTasks.size()));
			System.out.println("   - Adding from train split...");
			allTasks.addAll(Transforms.makeTasks("train"));
			System.out.println(String.format("     + Now have %s tasks...", allTasks.size()));
			System.out.println("   - Adding from valid split...");
			allTasks.addAll(Transforms.makeTasks("valid"));
			System.out.println(String.format("     + Now have %s tasks...", allTasks.size()));

			System.out.println("   - Running in parallel with 64 threads...");
			ExecutorService pool = Executors.newFixedThreadPool(64);

			pool.invokeAll(allTasks);

			pool.shutdown(); 
			System.out.println("   + Done!");
		} catch (Exception ex) {
			ex.printStackTrace();
			System.out.println(ex.toString());
		}
	}

}
