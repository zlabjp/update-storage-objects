/*
Copyright 2014 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
/*
Copyright 2018, Z Lab Corporation. All rights reserved.
Copyright 2018, update-storage-objects contributors

For the full copyright and license information, please view the LICENSE
file that was distributed with this source code.
*/

package main

import (
	goflag "flag"
	"fmt"
	"io"
	"os"

	"github.com/spf13/cobra"
	"k8s.io/apiserver/pkg/util/flag"
	cmdutil "k8s.io/kubernetes/pkg/kubectl/cmd/util"
	"k8s.io/kubernetes/pkg/kubectl/resource"
	"k8s.io/kubernetes/pkg/kubectl/util/logs"
	// Import to initialize client auth plugins.
	_ "k8s.io/client-go/plugin/pkg/client/auth"
)

func main() {
	f := cmdutil.NewFactory(nil)
	options := &resource.FilenameOptions{}

	cmd := &cobra.Command{
		Use: "kput -f FILENAME",
		Run: func(cmd *cobra.Command, args []string) {
			cmdutil.CheckErr(cmdutil.ValidateOutputArgs(cmd))
			err := run(f, os.Stdout, cmd, options)
			cmdutil.CheckErr(err)
		},
	}

	cmdutil.AddFilenameOptionFlags(cmd, options, "to use to put the resource.")
	cmdutil.AddValidateFlags(cmd)
	cmdutil.AddOutputFlagsForMutation(cmd)

	f.BindFlags(cmd.Flags())
	f.BindExternalFlags(cmd.Flags())

	cmd.Flags().SetNormalizeFunc(flag.WordSepNormalizeFunc)
	cmd.Flags().AddGoFlagSet(goflag.CommandLine)
	// Workaround for this issue: https://github.com/kubernetes/kubernetes/issues/17162
	goflag.CommandLine.Parse([]string{})

	logs.InitLogs()
	defer logs.FlushLogs()

	if err := cmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}
}

func run(f cmdutil.Factory, out io.Writer, cmd *cobra.Command, options *resource.FilenameOptions) error {
	schema, err := f.Validator(cmdutil.GetFlagBool(cmd, "validate"))
	if err != nil {
		return err
	}

	cmdNamespace, enforceNamespace, err := f.DefaultNamespace()
	if err != nil {
		return err
	}

	if cmdutil.IsFilenameSliceEmpty(options.Filenames) {
		return cmdutil.UsageErrorf(cmd, "Must specify --filename to put")
	}

	shortOutput := cmdutil.GetFlagString(cmd, "output") == "name"

	r := f.NewBuilder().
		Unstructured().
		Schema(schema).
		ContinueOnError().
		NamespaceParam(cmdNamespace).DefaultNamespace().
		FilenameParam(enforceNamespace, options).
		Flatten().
		Do()

	if err := r.Err(); err != nil {
		return err
	}

	return r.Visit(func(info *resource.Info, err error) error {
		if err != nil {
			return err
		}

		obj, err := resource.NewHelper(info.Client, info.Mapping).Replace(info.Namespace, info.Name, true, info.Object)
		if err != nil {
			return cmdutil.AddSourceToErr("putting", info.Source, err)
		}

		info.Refresh(obj, true)
		cmdutil.PrintSuccess(shortOutput, out, info.Object, false, "put")

		return nil
	})
}
