import spoon.Launcher;

public class Transforms {

	public static void main(String[] args) {
		final Launcher launcher = new Launcher();
		launcher.setArgs(args);

        try {
    		launcher.run();
        } catch (spoon.support.compiler.SnippetCompilationError ex) {

        }
	}

}
