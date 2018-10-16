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
	"flag"
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"k8s.io/apimachinery/pkg/runtime"
	utilflag "k8s.io/apiserver/pkg/util/flag"
	"k8s.io/cli-runtime/pkg/genericclioptions"
	"k8s.io/cli-runtime/pkg/genericclioptions/resource"
	cmdutil "k8s.io/kubernetes/pkg/kubectl/cmd/util"
	"k8s.io/kubernetes/pkg/kubectl/util/logs"
	"k8s.io/kubernetes/pkg/kubectl/validation"

	// Import to initialize client auth plugins.
	_ "k8s.io/client-go/plugin/pkg/client/auth"
)

type KputOptions struct {
	PrintFlags    *genericclioptions.PrintFlags
	FileNameFlags *genericclioptions.FileNameFlags

	FilenameOptions resource.FilenameOptions

	PrintObj func(obj runtime.Object) error

	validate bool

	Schema      validation.Schema
	Builder     func() *resource.Builder
	BuilderArgs []string

	Namespace        string
	EnforceNamespace bool

	genericclioptions.IOStreams
}

func NewKputOptions(streams genericclioptions.IOStreams) *KputOptions {
	outputFormat := ""
	usage := "to use to put the resource."

	filenames := []string{}
	recursive := false

	return &KputOptions{
		FileNameFlags: &genericclioptions.FileNameFlags{Usage: usage, Filenames: &filenames, Recursive: &recursive},
		PrintFlags: &genericclioptions.PrintFlags{
			OutputFormat:   &outputFormat,
			NamePrintFlags: genericclioptions.NewNamePrintFlags("putting"),
		},

		IOStreams: streams,
	}
}

func NewCmdKput(f cmdutil.Factory, streams genericclioptions.IOStreams) *cobra.Command {
	o := NewKputOptions(streams)

	cmd := &cobra.Command{
		Use: "kput -f FILENAME",
		Run: func(cmd *cobra.Command, args []string) {
			cmdutil.CheckErr(o.Complete(f, cmd, args))
			cmdutil.CheckErr(o.Validate(cmd))
			cmdutil.CheckErr(o.Run())
		},
	}

	o.FileNameFlags.AddFlags(cmd.Flags())
	o.PrintFlags.AddFlags(cmd)

	cmd.MarkFlagRequired("filename")
	cmdutil.AddValidateFlags(cmd)
	cmdutil.AddApplyAnnotationFlags(cmd)

	return cmd
}

func (o *KputOptions) Complete(f cmdutil.Factory, cmd *cobra.Command, args []string) error {
	var err error

	o.validate = cmdutil.GetFlagBool(cmd, "validate")

	printer, err := o.PrintFlags.ToPrinter()
	if err != nil {
		return err
	}
	o.PrintObj = func(obj runtime.Object) error {
		return printer.PrintObj(obj, o.Out)
	}

	o.FilenameOptions = o.FileNameFlags.ToOptions()

	schema, err := f.Validator(o.validate)
	if err != nil {
		return err
	}

	o.Schema = schema
	o.Builder = f.NewBuilder
	o.BuilderArgs = args

	o.Namespace, o.EnforceNamespace, err = f.ToRawKubeConfigLoader().Namespace()
	if err != nil {
		return err
	}

	return nil
}

func (o *KputOptions) Validate(cmd *cobra.Command) error {
	if cmdutil.IsFilenameSliceEmpty(o.FilenameOptions.Filenames) {
		return cmdutil.UsageErrorf(cmd, "Must specify --filename to put")
	}

	return nil
}

func (o *KputOptions) Run() error {
	r := o.Builder().
		Unstructured().
		Schema(o.Schema).
		ContinueOnError().
		NamespaceParam(o.Namespace).DefaultNamespace().
		FilenameParam(o.EnforceNamespace, &o.FilenameOptions).
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
		return o.PrintObj(info.Object)
	})
}

func main() {
	kubeConfigFlags := genericclioptions.NewConfigFlags()
	matchVersionKubeConfigFlags := cmdutil.NewMatchVersionFlags(kubeConfigFlags)
	f := cmdutil.NewFactory(matchVersionKubeConfigFlags)
	streams := genericclioptions.IOStreams{In: os.Stdin, Out: os.Stdout, ErrOut: os.Stderr}

	cmd := NewCmdKput(f, streams)

	flags := cmd.PersistentFlags()
	flags.SetNormalizeFunc(utilflag.WarnWordSepNormalizeFunc) // Warn for "_" flags

	// Normalize all flags that are coming from other packages or pre-configurations
	// a.k.a. change all "_" to "-". e.g. glog package
	flags.SetNormalizeFunc(utilflag.WordSepNormalizeFunc)

	kubeConfigFlags.AddFlags(flags)
	matchVersionKubeConfigFlags.AddFlags(cmd.PersistentFlags())
	cmd.PersistentFlags().AddGoFlagSet(flag.CommandLine)

	logs.InitLogs()
	defer logs.FlushLogs()

	if err := cmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}
}
