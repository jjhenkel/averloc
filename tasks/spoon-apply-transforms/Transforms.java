import spoon.Launcher;
import spoon.reflect.visitor.DefaultJavaPrettyPrinter;

public class Transforms {

	public static void main(String[] args) {
		final Launcher launcher = new Launcher();
	
		launcher.setArgs(args);
		launcher.getEnvironment().setPrettyPrinterCreator(() -> {
			DefaultJavaPrettyPrinter printer = new DefaultJavaPrettyPrinter(launcher.getEnvironment());
			printer.setIgnoreImplicit(false);
			return printer;
		});

		launcher.run();
	}

}
