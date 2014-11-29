#include <stdio.h>
#include <assert.h>

// File generated by --header switch inside the nimcache directory.
#include "test_c_api.h"

const char* valid_rst_filename = "temp_good.rst";
const char* bad_rst_filename = "temp_bad.rst";
const char* good_rst_include_filename = "include_good.rst";
const char* bad_rst_include_filename = "include_bad.rst";
const char* good_html_include_filename = "temp_include_good.html";
const char* bad_html_include_filename = "temp_include_bad.html";
const char* exception_message = "I was raised in a poor language";

char valid_rst_string[] = "Embedded *rst* text";
char bad_rst_string[] = "Asterisks and Obelix\n"
	"====================\n"
	"\n"
	"These asterisks* are bad for rst.\n"
	"\n"
	"* Not that we really care.\n"
	"\n"
	// The underscore will be replaced at runtime!
	"Or was <B it _single quotes?";

// Helper to write a null terminated string to a specific path.
void overwrite(const char* filename, const char* s)
{
	assert(filename && *filename);
	assert(s);
	FILE* file = fopen(filename, "w+");
	assert(file);
	fwrite(s, 1, strlen(s), file);
	fclose(file);
}

// Message callback to deal with errors, very verbose and never fails.
char* verbose_message_callback(char* filename,
	int line, int col, char kind, char* desc)
{
	printf("Woah woa wow, something happened in '%s'\n", filename);
	printf("Line %d, col %d, kind %c: '%s'\n", line, col, kind, desc);
	printf("Well, who cares…\n");
	return 0;
}

// Callback which nags at any ocassion with a serious existential problem.
char* silent_message_failure_callback(char* filename,
	int line, int col, char kind, char* desc)
{
	return exception_message;
}

// File handler which always fails silently.
void failure_file_callback(char* current_filename, char* target_filename,
	char* out_path, int out_size)
{
	return;
}

// Verbose file handler.
void verbose_file_callback(char* current_filename, char* target_filename,
	char* out_path, int out_size)
{
	printf("Got file request from '%s' to '%s'\n",
		current_filename, target_filename);
	// Copy the current_filename without overflow to the destination.
	strncpy(out_path, current_filename, out_size - 1);
	out_path[out_size - 1] = '\0';
	// Remove up to the last path separator
	char* s = strrchr(out_path, '/');
	if (s) {
		*(++s) = 0;
	} else if (s = strrchr(out_path, '\\')) {
		*(++s) = 0;
	} else {
		// No path separators? Clean target.
		*(s = out_path) = 0;
	}
	strncpy(s, target_filename, out_size - 1 - (s - out_path));
	printf("Will return '%s'\n", out_path);
}

// Entry point of the C test.
void run_c_test(char* error_rst, char* special_options)
{
	// Due to backticks being escaped in Nimrod's emit pragma (see
	// https://github.com/Araq/Nimrod/issues/1588) we have to modify
	// bad_rst_string at runtime to avoid it being escaped during Nimrod's C
	// codegen phase.
	assert(strchr(bad_rst_string, '_'));
	*strchr(bad_rst_string, '_') = 0x60;

	// Generates files with rst content.
	{
		overwrite(valid_rst_filename, valid_rst_string);
		overwrite(bad_rst_filename, bad_rst_string);
	}

	printf("Using lazy_rest %s.\n", lr_version_str());

	int major = 6, minor = 6, maintenance = 6;
	lr_version_int(&major, &minor, &maintenance);
	printf("Using lazy_rest: %d-%d-%d.\n",
		major, minor, maintenance);

	// Tests unsafe string conversions.
	{
		char* s = lr_rst_string_to_html(valid_rst_string,
			"<string>", 0);
		assert(0 != s);
		if (s) {
			// Success!
			assert(strstr(s, "<title>"));
			overwrite("temp_string_to_html.html", s);
		} else {
			// Handle error.
		}
	}

	{
		char* s = lr_rst_string_to_html(bad_rst_string,
			"<bad-string>", 0);
		assert(0 == s);
		if (!s) {
			// Handle error.
			printf("1 Ignore the next error message, it's expected\n");
			printf("Error processing string: %s\n",
				lr_rst_string_to_html_error());
		}
	}

	// Tests unsafe file conversions.
	{
		char* s = lr_rst_file_to_html(valid_rst_filename, 0);
		assert(0 != s);
		if (s) {
			// Success!
			overwrite("temp_file_to_html.html", s);
		} else {
			// Handle error.
		}
	}

	{
		char* s = lr_rst_file_to_html(bad_rst_filename, 0);
		assert(0 == s);
		if (!s) {
			// Handle error.
			printf("2 Ignore the next error message, it's expected\n");
			printf("Error processing file: %s\n",
				lr_rst_file_to_html_error());
		}
	}

	// Test the safe string conversions.
	{
		char* s = lr_safe_rst_string_to_html(
			"<filename>", valid_rst_string, 0, 0);
		overwrite("temp_safe_string_1.html", s);
		assert(s);
		assert(strstr(s, "<title>"));
		int errors = 1;
		s = lr_safe_rst_string_to_html(
			"<filename>", valid_rst_string, &errors, 0);
		assert(0 == errors);
		overwrite("temp_safe_string_2.html", s);
		if (s) {
			// Success!
		} else {
			// Handle error.
		}
	}

	{
		char* s = lr_safe_rst_string_to_html(
			"<filename>", bad_rst_string, 0, 0);
		assert(s);
		assert(strstr(s, "<title>"));
		overwrite("temp_safe_string_3.html", s);
		int errors = 0;
		s = lr_safe_rst_string_to_html(
			"<filename>", bad_rst_string, &errors, 0);
		assert(errors > 0);
		overwrite("temp_safe_string_4.html", s);
		if (errors) {
			// Handle error.
			printf("3 Ignore the next error message, it's expected\n");
			printf("RST error stack trace:\n");
			while (errors) {
				printf("\t%s\n",
					lr_safe_rst_string_to_html_error(--errors));
			}
		}
	}

	// Test the safe file conversions.
	{
		char* s = lr_safe_rst_file_to_html(
			valid_rst_filename, 0, 0);
		overwrite("temp_safe_file_1.html", s);
		assert(s);
		assert(strstr(s, "<title>"));
		int errors = 1;
		s = lr_safe_rst_file_to_html(
			valid_rst_filename, &errors, 0);
		assert(0 == errors);
		overwrite("temp_safe_file_2.html", s);
		if (s) {
			// Success!
		} else {
			// Handle error.
		}
	}

	{
		char* s = lr_safe_rst_file_to_html(
			bad_rst_filename, 0, 0);
		assert(s);
		assert(strstr(s, "<title>"));
		overwrite("temp_safe_file_3.html", s);
		int errors = 0;
		s = lr_safe_rst_file_to_html(
			bad_rst_filename, &errors, 0);
		assert(errors > 0);
		overwrite("temp_safe_file_4.html", s);
		if (errors) {
			// Handle error.
			printf("4 Ignore the next error message, it's expected\n");
			printf("RST error stack trace:\n");
			while (errors) {
				printf("\t%s\n",
					lr_safe_rst_file_to_html_error(--errors));
			}
		}
	}

	// Tests the nim file conversion.
	{
		char* s = lr_nim_file_to_html("test_c_api.nim", 1, 0);
		overwrite("temp_nim_file_1.html", s);
		s = lr_nim_file_to_html("test_c_api.nim", 0, 0);
		overwrite("temp_nim_file_2.html", s);
	}

	// Test normal error rst.
	{
		if (lr_set_normal_error_rst(error_rst)) {
			// Handle error.
			assert(0 && "lr_set_normal_error_rst");
		} else {
			assert(1);
			char* s = lr_safe_rst_file_to_html(
				bad_rst_filename, 0, 0);
			assert(s);
			assert(strstr(s, "<title>"));
			overwrite("temp_set_error_template_1.html", s);
		}

		int errors = lr_set_normal_error_rst(bad_rst_string);
		assert(errors);
		if (errors) {
			printf("5 Ignore the next error messages\n");
			printf("Could not set normal error rst!\n");
			while (errors) {
				printf("\t%s\n",
					lr_set_normal_error_rst_error(--errors));
			}
		}
	}

	// Test option override.
	{
		int did_change = lr_set_global_rst_options(special_options);
		assert(did_change && "Did fail changing global options?");

		char* s = lr_safe_rst_file_to_html(
			bad_rst_filename, 0, 0);
		overwrite("temp_global_options_1.html", s);
		s = lr_safe_rst_file_to_html(
			valid_rst_filename, 0, 0);
		overwrite("temp_global_options_2.html", s);

		// Reset back to nil.
		did_change = lr_set_global_rst_options(0);
		assert(!did_change);
		s = lr_safe_rst_file_to_html(
			valid_rst_filename, 0, 0);
		overwrite("temp_global_options_3.html", s);
	}

	// Verify changing the message callback works.
	{
		// Test error condition.
		char* s = lr_rst_string_to_html(bad_rst_string,
			"<bad-string>", 0);
		assert(0 == s && "Should return nil due to parsing errors");
		// Change to custom callback which ignores errors.
		lr_set_nim_msg_handler(ignore_msg_handler);
		s = lr_rst_string_to_html(bad_rst_string, "<bad-string>", 0);
		assert(s && "Should return non nil due to ignored errors");
		// Now go back to an error handler, but with nil output.
		lr_set_nim_msg_handler(0);
		s = lr_rst_string_to_html(bad_rst_string, "<bad-string>", 0);
		assert(0 == s && "Should return nil due to errors");

		// Retry custom verbose C callback which never fails.
		printf("Ignore the following verbose error…\n");
		lr_set_c_msg_handler(verbose_message_callback);
		s = lr_rst_string_to_html(bad_rst_string, "<bad-string>", 0);
		assert(s && "Should return non nil due to ignored errors");
		// Repeat with a callback which should fail, verify the error.
		lr_set_c_msg_handler(silent_message_failure_callback);
		s = lr_rst_string_to_html(bad_rst_string, "<bad-string>", 0);
		assert(0 == s && "Should return nil due to errors");
		printf("Verbose C error: %s\n", lr_rst_string_to_html_error());
		assert(0 == strcmp(lr_rst_string_to_html_error(), exception_message));
		// Go back to Nimrod default handler.
		lr_set_c_msg_handler(0);
		s = lr_rst_string_to_html(bad_rst_string, "<bad-string>", 0);
		assert(0 == s && "Should return nil due to errors");
	}

	// Test the Nimrod find file callbacks.
	{
		char* s;
		int errors = 1;

		s = lr_safe_rst_file_to_html(
			good_rst_include_filename, &errors, 0);
		overwrite(good_html_include_filename, s);
		assert(0 == errors);

		s = lr_safe_rst_file_to_html(
			bad_rst_include_filename, &errors, 0);
		assert(1 == errors);
		overwrite(bad_html_include_filename, s);

		// Changing the file handler will make all includes fail.
		lr_set_nim_find_file_handler(lr_nil_find_file_handler);
		s = lr_safe_rst_file_to_html(
			good_rst_include_filename, &errors, 0);
		assert(1 == errors && "now everything fails");
	}

	// Test the C find file callbacks.
	{
		char* s;
		int errors = 1;

		// Make sure the nimrod file handler is nil, we override it from C.
		lr_set_nim_find_file_handler(lr_nil_find_file_handler);
		printf("Current file handler buffer size %d\n",
			lr_set_find_file_buffer_size(-1));
		lr_set_c_find_file_handler(verbose_file_callback);

		s = lr_safe_rst_file_to_html(
			good_rst_include_filename, &errors, 0);
		assert(0 == errors);

		s = lr_safe_rst_file_to_html(
			bad_rst_include_filename, &errors, 0);
		assert(1 == errors);
		overwrite(bad_html_include_filename, s);

		// Set valid Nimrod handler and nil C which should fail all tests.
		lr_set_nim_find_file_handler(lr_unrestricted_find_file_handler);
		lr_set_c_find_file_handler(failure_file_callback);
		s = lr_safe_rst_file_to_html(
			good_rst_include_filename, &errors, 0);
		assert(1 == errors);
		// Resetting this to null should make files work again.
		lr_set_c_find_file_handler(0);
		s = lr_safe_rst_file_to_html(
			good_rst_include_filename, &errors, 0);
		assert(0 == errors);
	}
}
